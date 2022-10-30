import UnityEngine

[ExecuteInEditMode]
[RequireComponent(Camera)]
[AddComponentMenu("Image Effects/Bloom")]
class Bloom(PostEffectBase):

	enum TweakMode:
		Basic
		Complex

	enum BloomScreenBlendMode:
		Screen
		Add

	enum HDRBloomMode:
		Auto
		On
		Off

	enum BloomQuality:
		Cheap
		High

	enum LensFlareMode:
		Ghosting
		Anamorphic
		Combined

	public tweakMode as TweakMode = TweakMode.Basic
	public screenBlendMode as BloomScreenBlendMode = BloomScreenBlendMode.Add

	public hdr as HDRBloomMode = HDRBloomMode.Auto
	private doHdr as bool = false

	public blurSpread as single = 2.5f

	public quality as BloomQuality = BloomQuality.High

	public bloomIntensity as single = 0.5f
	public bloomThreshold as single = 0.5f
	public bloomThresholdColor as Color = Color.white
	public bloomBlurIterations as int = 2

	public hollywoodFlareBlurIterations as int = 2
	public flareRotation as single = 0.0f
	public lensFlareMode as LensFlareMode = LensFlareMode.Anamorphic
	public hollywoodStretchWidth as single = 2.5f
	public lensFlareIntensity as single = 0.0f
	public lensFlareThreshold as single = 0.3f
	public lensFlareSaturation as single = 0.75f
	public flareColorA as Color = Color(0.4f, 0.4f, 0.8f, 0.75f)
	public flareColorB as Color = Color(0.4f, 0.8f, 0.8f, 0.75f)
	public flareColorC as Color = Color(0.8f, 0.4f, 0.8f, 0.75f)
	public flareColorD as Color = Color(0.8f, 0.4f, 0.0f, 0.75f)
	public blurWidth as single = 1.0f
	public lensFlareVignetteMask as Texture2D

	public lensFlareShader as Shader
	private lensFlareMaterial as Material

	public screenBlendShader as Shader
	private screenBlend as Material

	public blurAndFlaresShader as Shader
	private blurAndFlaresMaterial as Material

	public brightPassFilterShader as Shader
	private brightPassFilterMaterial as Material

	override def CheckResources() as bool:
		CheckSupport(false)

		screenBlend = CheckShaderAndCreateMaterial(screenBlendShader, screenBlend)
		lensFlareMaterial = CheckShaderAndCreateMaterial(lensFlareShader,lensFlareMaterial)
		blurAndFlaresMaterial = CheckShaderAndCreateMaterial(blurAndFlaresShader, blurAndFlaresMaterial)
		brightPassFilterMaterial = CheckShaderAndCreateMaterial(brightPassFilterShader, brightPassFilterMaterial)

		if not isSupported:
			ReportAutoDisable()
		return isSupported

	def OnRenderImage(source as RenderTexture, destination as RenderTexture):
		if CheckResources() == false:
			Graphics.Blit(source, destination)
			return

		// screen blend is not supported when HDR is enabled (will cap values)
		doHdr = false
		if hdr == HDRBloomMode.Auto:
			doHdr = source.format == RenderTextureFormat.ARGBHalf and camera.hdr
		else:
			doHdr = hdr == HDRBloomMode.On

		doHdr = doHdr and supportHDRTextures

		realBlendMode = screenBlendMode
		if doHdr:
			realBlendMode = BloomScreenBlendMode.Add

		rtFormat = (RenderTextureFormat.ARGBHalf if doHdr else RenderTextureFormat.Default)
		rtW2 = source.width / 2
		rtH2 = source.height / 2
		rtW4 = source.width / 4
		rtH4 = source.height / 4

		widthOverHeight = (1.0f * source.width) / (1.0f * source.height)
		oneOverBaseSize = 1.0f / 512.0f

		// downsample
		quarterRezColor = RenderTexture.GetTemporary(rtW4, rtH4, 0, rtFormat)
		halfRezColorDown = RenderTexture.GetTemporary(rtW2, rtH2, 0, rtFormat)
		if quality > BloomQuality.Cheap:
			Graphics.Blit(source, halfRezColorDown, screenBlend, 2)
			rtDown4 = RenderTexture.GetTemporary(rtW4, rtH4, 0, rtFormat)
			Graphics.Blit(halfRezColorDown, rtDown4, screenBlend, 2)
			Graphics.Blit(rtDown4, quarterRezColor, screenBlend, 6)
			RenderTexture.ReleaseTemporary(rtDown4)
		else:
			Graphics.Blit(source, halfRezColorDown)
			Graphics.Blit(halfRezColorDown, quarterRezColor, screenBlend, 6)
		RenderTexture.ReleaseTemporary(halfRezColorDown)

		// cut colors (thresholding)
		secondQuarterRezColor = RenderTexture.GetTemporary(rtW4, rtH4, 0, rtFormat)
		BrightFilter(bloomThreshold * bloomThresholdColor, quarterRezColor, secondQuarterRezColor)

		// blurring
		if bloomBlurIterations < 1:
			bloomBlurIterations = 1
		elif bloomBlurIterations > 10:
			bloomBlurIterations = 10

		for iter in range(bloomBlurIterations):
			spreadForPass = (1.0f + (iter * 0.25f)) * blurSpread

			// vertical blur
			blur4 = RenderTexture.GetTemporary(rtW4, rtH4, 0, rtFormat)
			blurAndFlaresMaterial.SetVector("_Offsets", Vector4(0.0f, spreadForPass * oneOverBaseSize, 0.0f, 0.0f))
			Graphics.Blit(secondQuarterRezColor, blur4, blurAndFlaresMaterial, 4)
			RenderTexture.ReleaseTemporary(secondQuarterRezColor)
			secondQuarterRezColor = blur4

			// horizontal blur
			blur4 = RenderTexture.GetTemporary(rtW4, rtH4, 0, rtFormat)
			blurAndFlaresMaterial.SetVector("_Offsets", Vector4((spreadForPass / widthOverHeight) * oneOverBaseSize, 0.0f, 0.0f, 0.0f))
			Graphics.Blit(secondQuarterRezColor, blur4, blurAndFlaresMaterial, 4)
			RenderTexture.ReleaseTemporary(secondQuarterRezColor)
			secondQuarterRezColor = blur4

			if quality > BloomQuality.Cheap:
				if iter == 0:
					Graphics.SetRenderTarget(quarterRezColor)
					GL.Clear(false, true, Color.black) // Clear to avoid RT restore
					Graphics.Blit(secondQuarterRezColor, quarterRezColor)
				else:
					quarterRezColor.MarkRestoreExpected() // using max blending, RT restore expected
					Graphics.Blit(secondQuarterRezColor, quarterRezColor, screenBlend, 10)

		if quality > BloomQuality.Cheap:
			Graphics.SetRenderTarget(secondQuarterRezColor)
			GL.Clear(false, true, Color.black) // Clear to avoid RT restore
			Graphics.Blit(quarterRezColor, secondQuarterRezColor, screenBlend, 6)

		// lens flares: ghosting, anamorphic or both (ghosted anamorphic flares)
		if lensFlareIntensity > Mathf.Epsilon:
			rtFlares4 = RenderTexture.GetTemporary(rtW4, rtH4, 0, rtFormat)

			if lensFlareMode == 0:
				// ghosting only
				BrightFilter(lensFlareThreshold, secondQuarterRezColor, rtFlares4)

				if quality > BloomQuality.Cheap:
					// smooth a little
					blurAndFlaresMaterial.SetVector("_Offsets", Vector4(0.0f, (1.5f) / (1.0f * quarterRezColor.height), 0.0f, 0.0f))
					Graphics.SetRenderTarget(quarterRezColor)
					GL.Clear(false, true, Color.black) // Clear to avoid RT restore
					Graphics.Blit(rtFlares4, quarterRezColor, blurAndFlaresMaterial, 4)

					blurAndFlaresMaterial.SetVector("_Offsets", Vector4((1.5f) / (1.0f * quarterRezColor.width), 0.0f, 0.0f, 0.0f))
					Graphics.SetRenderTarget(rtFlares4)
					GL.Clear(false, true, Color.black) // Clear to avoid RT restore
					Graphics.Blit(quarterRezColor, rtFlares4, blurAndFlaresMaterial, 4)

				// no ugly edges!
				Vignette(0.975f, rtFlares4, rtFlares4)
				BlendFlares(rtFlares4, secondQuarterRezColor)
			else:
				//Vignette(0.975f, rtFlares4, rtFlares4)
				//DrawBorder(rtFlares4, screenBlend, 8)

				flareXRot = 1.0f * Mathf.Cos(flareRotation)
				flareyRot = 1.0f * Mathf.Sin(flareRotation)

				stretchWidth = (hollywoodStretchWidth * 1.0f / widthOverHeight) * oneOverBaseSize

				blurAndFlaresMaterial.SetVector("_Offsets", Vector4(flareXRot, flareyRot, 0.0, 0.0))
				blurAndFlaresMaterial.SetVector("_Threshold", Vector4(lensFlareThreshold, 1.0f, 0.0f, 0.0f))
				blurAndFlaresMaterial.SetVector("_TintColor", Vector4(flareColorA.r, flareColorA.g, flareColorA.b, flareColorA.a) * flareColorA.a * lensFlareIntensity)
				blurAndFlaresMaterial.SetFloat("_Saturation", lensFlareSaturation)

				// "pre and cut"
				quarterRezColor.DiscardContents()
				Graphics.Blit(rtFlares4, quarterRezColor, blurAndFlaresMaterial, 2)
				// "post"
				rtFlares4.DiscardContents()
				Graphics.Blit(quarterRezColor, rtFlares4, blurAndFlaresMaterial, 3)

				blurAndFlaresMaterial.SetVector("_Offsets", Vector4(flareXRot * stretchWidth, flareyRot * stretchWidth, 0.0, 0.0))
				// stretch 1st
				blurAndFlaresMaterial.SetFloat("_StretchWidth", hollywoodStretchWidth)
				quarterRezColor.DiscardContents()
				Graphics.Blit(rtFlares4, quarterRezColor, blurAndFlaresMaterial, 1)
				// stretch 2nd
				blurAndFlaresMaterial.SetFloat("_StretchWidth", hollywoodStretchWidth * 2.0f)
				rtFlares4.DiscardContents()
				Graphics.Blit(quarterRezColor, rtFlares4, blurAndFlaresMaterial, 1)
				// stretch 3rd
				blurAndFlaresMaterial.SetFloat("_StretchWidth", hollywoodStretchWidth * 4.0f)
				quarterRezColor.DiscardContents()
				Graphics.Blit(rtFlares4, quarterRezColor, blurAndFlaresMaterial, 1)

				// additional blur passes
				for iter in range(hollywoodFlareBlurIterations):
					stretchWidth = (hollywoodStretchWidth * 2.0f / widthOverHeight) * oneOverBaseSize

					blurAndFlaresMaterial.SetVector("_Offsets", Vector4(stretchWidth * flareXRot, stretchWidth * flareyRot, 0.0, 0.0))
					rtFlares4.DiscardContents()
					Graphics.Blit(quarterRezColor, rtFlares4, blurAndFlaresMaterial, 4)

					blurAndFlaresMaterial.SetVector("_Offsets", Vector4(stretchWidth * flareXRot, stretchWidth * flareyRot, 0.0, 0.0))
					quarterRezColor.DiscardContents()
					Graphics.Blit(rtFlares4, quarterRezColor, blurAndFlaresMaterial, 4)

				if lensFlareMode == 1:
					// anamorphic lens flares
					AddTo(1.0, quarterRezColor, secondQuarterRezColor)
				else:
					// "combined" lens flares
					Vignette(1.0, quarterRezColor, rtFlares4)
					BlendFlares(rtFlares4, quarterRezColor)
					AddTo(1.0, quarterRezColor, secondQuarterRezColor)
			RenderTexture.ReleaseTemporary(rtFlares4)

		blendPass = realBlendMode
		//if Mathf.Abs(chromaticBloom) < Mathf.Epsilon:
		//	blendPass += 4;

		screenBlend.SetFloat("_Intensity", bloomIntensity)
		screenBlend.SetTexture("_ColorBuffer", source)

		if quality > BloomQuality.Cheap:
			halfRezColorUp = RenderTexture.GetTemporary(rtW2, rtH2, 0, rtFormat)
			Graphics.Blit(secondQuarterRezColor, halfRezColorUp)
			Graphics.Blit(halfRezColorUp, destination, screenBlend, blendPass)
			RenderTexture.ReleaseTemporary(halfRezColorUp)
		else:
			Graphics.Blit(secondQuarterRezColor, destination, screenBlend, blendPass)

		RenderTexture.ReleaseTemporary(quarterRezColor)
		RenderTexture.ReleaseTemporary(secondQuarterRezColor)

	private def AddTo(intensity as single, first as RenderTexture, second as RenderTexture):
		screenBlend.SetFloat("_Intensity", intensity)
		second.MarkRestoreExpected() // additive blending, RT restore expected
		Graphics.Blit(first, second, screenBlend, 9)

	private def BlendFlares(first as RenderTexture, second as RenderTexture):
		lensFlareMaterial.SetVector("colorA", Vector4(flareColorA.r, flareColorA.g, flareColorA.b, flareColorA.a) * lensFlareIntensity)
		lensFlareMaterial.SetVector("colorB", Vector4(flareColorB.r, flareColorB.g, flareColorB.b, flareColorB.a) * lensFlareIntensity)
		lensFlareMaterial.SetVector("colorC", Vector4(flareColorC.r, flareColorC.g, flareColorC.b, flareColorC.a) * lensFlareIntensity)
		lensFlareMaterial.SetVector("colorD", Vector4(flareColorD.r, flareColorD.g, flareColorD.b, flareColorD.a) * lensFlareIntensity)
		second.MarkRestoreExpected() // additive blending, RT restore expected
		Graphics.Blit(first, second, lensFlareMaterial)		

	private def BrightFilter(threshold as single, first as RenderTexture, second as RenderTexture):
		brightPassFilterMaterial.SetVector("_Threshold", Vector4(threshold, threshold, threshold, threshold))
		Graphics.Blit(first, second, brightPassFilterMaterial, 0)

	private def BrightFilter(thresholdColor as Color, first as RenderTexture, second as RenderTexture):
		brightPassFilterMaterial.SetVector("_Threshold", thresholdColor)
		Graphics.Blit(first, second, brightPassFilterMaterial, 1)

	private def Vignette(amount as single, first as RenderTexture, second as RenderTexture):
		if lensFlareVignetteMask:
			screenBlend.SetTexture("_ColorBuffer", lensFlareVignetteMask)
			second.MarkRestoreExpected() // using blending, RT restore expected
			Graphics.Blit((null if first == second else first), second, screenBlend, (7 if first == second else 3))
		elif first != second:
			Graphics.SetRenderTarget(second)
			GL.Clear(false, true, Color.black) // clear destination to avoid RT restore
			Graphics.Blit(first, second)