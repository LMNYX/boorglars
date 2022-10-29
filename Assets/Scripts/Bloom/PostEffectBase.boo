import UnityEngine

[ExecuteInEditMode]
[RequireComponent(Camera)]
class PostEffectBase(MonoBehaviour):
	
	protected supportHDRTextures as bool = true
	protected supportDX11 as bool = false
	protected isSupported as bool = true
	
	def CheckShaderAndCreateMaterial(s as Shader, m2Create as Material):
		if (not s):
			Debug.Log("Missing shader ${self.ToString()}")
			enabled = false
			return null
		
		if (s.isSupported and m2Create and m2Create.shader == s):
			return m2Create
		
		if (not s.isSupported):
			NotSupported()
			Debug.Log("The shader $(s.ToString()) on effect $(self.ToString()) is not supported on this platform!")
			return null
		else:
			m2Create = Material(s)
			m2Create.hideFlags = HideFlags.DontSave
			if (m2Create):
				return m2Create
			else: return null
		
	def OnEnable():
		self.isSupported = true
	
	def CheckSupport(): // ??? unity??
		return CheckSupport(false, false)
	
	def CheckResources():
		Debug.LogWarning("CheckResources () for $(self.ToString()) should be overwritten.")
		return isSupported
		
	def Start():
		CheckResources()
	
	def CheckSupport(needDepth as bool):
		isSupported = true
		supportHDRTextures = SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.ARGBHalf)
		supportDX11 = SystemInfo.graphicsShaderLevel >= 50 and SystemInfo.supportsComputeShaders
		
		if (not SystemInfo.supportsImageEffects or not SystemInfo.supportsRenderTextures):
			NotSupported()
			return false
		
		if (needDepth and not SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.Depth)):
			NotSupported()
			return false
		
		if (needDepth):
			camera.depthTextureMode = camera.depthTextureMode | DepthTextureMode.Depth
		
		return true
	
	def CheckSupport(needDepth as bool, needHdr as bool):
		if (not CheckSupport(needDepth)):
			return false
		
		if(needHdr and not supportHDRTextures):
			NotSupported()
			return false
		
		return true
	
	def Dx11Support():
		return supportDX11
	
	def ReportAutoDisable():
		Debug.LogWarning("The image effect $(self.ToString()) has been disabled as it's not supported on the current platform")
	
	// deprecated but needed for old effects to survive upgrading
	def CheckShader(s as Shader):
		Debug.Log("The shader $(s.ToString) on effect $(self.ToString()) is not of the Unity 3.2+ effects suite anymore.")
		if (not s.isSupported):
			NotSupported()
		return false
	
	def NotSupported():
		enabled = false
		isSupported = false
		return
	
	def DrawBorder(dest as RenderTexture, material as Material):
		x1 as single
		x2 as single
		y1 as single
		y2 as single
		
		RenderTexture.active = dest
		invertY as bool = true
		
		GL.PushMatrix()
		GL.LoadOrtho()
		
		for i in range(material.passCount):
			material.SetPass(i)
			
			_y1 as single
			_y2 as single
			
			if (invertY):
				_y1 = 1.0
				_y2 = 0.0
			else:
				_y1 = 0.0
				_y2 = 1.0
			
			// left
			
			x1 = 0.0
			x2 = 0.0 + 1.0 / (dest.width * 1.0)
			
			y1 = 0.0
			y2 = 1.0
			
			GL.Begin(GL.QUADS)
			
			GL.TexCoord2(0.0, _y1)
			GL.Vertex3(x1, y1, 0.1)
			GL.TexCoord2(1.0, _y1)
			GL.Vertex3(x2, y1, 0.1)
			GL.TexCoord2(1.0, _y2)
			GL.Vertex3(x2, y2, 0.1)
			GL.TexCoord2(0.0, _y2)
			GL.Vertex3(x1, y2, 0.1)
			
			// right
			x1 = 1.0 - 1.0 / (dest.width * 1.0)
			x2 = 1.0
			
			y1 = 0.0
			y2 = 1.0
			
			GL.Begin(GL.QUADS)
			
			GL.TexCoord2(0.0, _y1)
			GL.Vertex3(x1, y1, 0.1)
			GL.TexCoord2(1.0, _y1)
			GL.Vertex3(x2, y1, 0.1)
			GL.TexCoord2(1.0, _y2)
			GL.Vertex3(x2, y2, 0.1)
			GL.TexCoord2(0.0, _y2)
			GL.Vertex3(x1, y2, 0.1)
			
			// top
			x1 = 0.0
			x2 = 1.0
			
			y1 = 0.0
			y2 = 0.0 + 1.0 / (dest.height * 1.0)
			
			GL.Begin(GL.QUADS)
			
			GL.TexCoord2(0.0, _y1)
			GL.Vertex3(x1, y1, 0.1)
			GL.TexCoord2(1.0, _y1)
			GL.Vertex3(x2, y1, 0.1)
			GL.TexCoord2(1.0, _y2)
			GL.Vertex3(x2, y2, 0.1)
			GL.TexCoord2(0.0, _y2)
			GL.Vertex3(x1, y2, 0.1)
			
			// bottom
			x1 = 0.0
			x2 = 1.0
			
			y1 = 1.0 - 1.0 / (dest.height * 1.0)
			y2 = 0.0
			
			GL.Begin(GL.QUADS)
			
			GL.TexCoord2(0.0, _y1)
			GL.Vertex3(x1, y1, 0.1)
			GL.TexCoord2(1.0, _y1)
			GL.Vertex3(x2, y1, 0.1)
			GL.TexCoord2(1.0, _y2)
			GL.Vertex3(x2, y2, 0.1)
			GL.TexCoord2(0.0, _y2)
			GL.Vertex3(x1, y2, 0.1)
			
			GL.End()
		
		GL.PopMatrix()
