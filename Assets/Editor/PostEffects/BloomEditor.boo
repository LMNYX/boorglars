[CustomEditor(Bloom)]
class BloomEditor(Editor):

	tweakMode as SerializedProperty
	screenBlendMode as SerializedProperty

	serObj as SerializedObject

	hdr as SerializedProperty
	quality as SerializedProperty
	blurSpread as SerializedProperty

	bloomIntensity as SerializedProperty
	bloomThresholdColor as SerializedProperty
	bloomThreshold as SerializedProperty
	bloomBlurIterations as SerializedProperty

	hollywoodFlareBlurIterations as SerializedProperty

	lensFlareMode as SerializedProperty
	hollywoodStretchWidth as SerializedProperty
	lensFlareIntensity as SerializedProperty
	flareRotation as SerializedProperty
	lensFlareSaturation as SerializedProperty
	lensFlareThreshold as SerializedProperty
	flareColorA as SerializedProperty
	flareColorB as SerializedProperty
	flareColorC as SerializedProperty
	flareColorD as SerializedProperty

	blurWidth as SerializedProperty
	lensFlareVignetteMask as SerializedProperty

	def OnEnable():
		serObj = SerializedObject(target)

		screenBlendMode = serObj.FindProperty("screenBlendMode")
		hdr = serObj.FindProperty("hdr")
		quality = serObj.FindProperty("quality")

		blurSpread = serObj.FindProperty("blurSpread")

		bloomIntensity = serObj.FindProperty("bloomIntensity")
		bloomThreshold = serObj.FindProperty("bloomThreshold")
		bloomThresholdColor = serObj.FindProperty("bloomThresholdColor")
		bloomBlurIterations = serObj.FindProperty("bloomBlurIterations")

		lensFlareMode = serObj.FindProperty("lensFlareMode")
		hollywoodFlareBlurIterations = serObj.FindProperty("hollywoodFlareBlurIterations")
		hollywoodStretchWidth = serObj.FindProperty("hollywoodStretchWidth")
		lensFlareIntensity = serObj.FindProperty("lensFlareIntensity")
		lensFlareThreshold = serObj.FindProperty("lensFlareThreshold")
		lensFlareSaturation = serObj.FindProperty("lensFlareSaturation")
		flareRotation = serObj.FindProperty("flareRotation")
		flareColorA = serObj.FindProperty("flareColorA")
		flareColorB = serObj.FindProperty("flareColorB")
		flareColorC = serObj.FindProperty("flareColorC")
		flareColorD = serObj.FindProperty("flareColorD")
		blurWidth = serObj.FindProperty("blurWidth")
		lensFlareVignetteMask = serObj.FindProperty("lensFlareVignetteMask")

		tweakMode = serObj.FindProperty("tweakMode")

	def OnInspectorGUI():
		serObj.Update()

		EditorGUILayout.LabelField("Glow and Lens Flares for bright screen pixels", EditorStyles.miniLabel)

		EditorGUILayout.PropertyField(quality, GUIContent("Quality", "High quality preserves high frequencies with bigger blurs and uses a better blending and down-/upsampling"))

		EditorGUILayout.Separator()

		EditorGUILayout.PropertyField(tweakMode, GUIContent("Mode"))
		EditorGUILayout.PropertyField(screenBlendMode, GUIContent("Blend"))
		EditorGUILayout.PropertyField(hdr, GUIContent("HDR"))

		EditorGUILayout.Separator()

		// display info text when screen blend mode cannot be used
		cam = (target as Bloom).camera
		if cam != null:
			if screenBlendMode.enumValueIndex == 0 and ((cam.hdr and hdr.enumValueIndex == 0) or hdr.enumValueIndex == 1):
				EditorGUILayout.HelpBox("Screen blend is not supported in HDR. Using 'Add' instead.", MessageType.Info)

		EditorGUILayout.PropertyField(bloomIntensity, GUIContent("Intensity"))
		bloomThreshold.floatValue = EditorGUILayout.Slider("Threshold", bloomThreshold.floatValue, -0.05, 4.0)
		if tweakMode.intValue == 1:
			EditorGUILayout.PropertyField(bloomThresholdColor, GUIContent(" RGB Threshold"))
		EditorGUILayout.Separator()

		bloomBlurIterations.intValue = EditorGUILayout.IntSlider("Blur Iterations", bloomBlurIterations.intValue, 1, 4)
		blurSpread.floatValue = EditorGUILayout.Slider(" Sample Distance", blurSpread.floatValue, 0.1, 10.0)
		EditorGUILayout.Separator()

		if tweakMode.intValue == 1:
			// further lens flare tweakings
			if tweakMode.intValue != 0:
				EditorGUILayout.PropertyField(lensFlareMode, GUIContent("Lens Flares"))
			else:
				lensFlareMode.enumValueIndex = 0

			EditorGUILayout.PropertyField(lensFlareIntensity, GUIContent(" Local Intensity", "0 disables lens flares entirely (optimization)"))
			lensFlareThreshold.floatValue = EditorGUILayout.Slider("  Threshold", lensFlareThreshold.floatValue, 0.0, 4.0f)

			if Mathf.Abs(lensFlareIntensity.floatValue) > Mathf.Epsilon:
				if lensFlareMode.intValue == 0:
					// ghosting
					EditorGUILayout.BeginHorizontal()
					EditorGUILayout.PropertyField(flareColorA, GUIContent(" 1st Color"))
					EditorGUILayout.PropertyField(flareColorB, GUIContent(" 2nd Color"))
					EditorGUILayout.EndHorizontal()

					EditorGUILayout.BeginHorizontal()
					EditorGUILayout.PropertyField(flareColorC, GUIContent(" 3rd Color"))
					EditorGUILayout.PropertyField(flareColorD, GUIContent(" 4th Color"))
					EditorGUILayout.EndHorizontal()
				elif lensFlareMode.intValue == 1:
					// hollywood
					EditorGUILayout.PropertyField(hollywoodStretchWidth, GUIContent(" Stretch width"))
					EditorGUILayout.PropertyField(flareRotation, GUIContent(" Rotation"))
					hollywoodFlareBlurIterations.intValue = EditorGUILayout.IntSlider(" Blur Iterations", hollywoodFlareBlurIterations.intValue, 1, 4)

					EditorGUILayout.PropertyField(lensFlareSaturation, GUIContent(" Saturation"))
					EditorGUILayout.PropertyField(flareColorA, GUIContent(" Tint Color"))
				elif lensFlareMode.intValue == 2:
					// both
					EditorGUILayout.PropertyField(hollywoodStretchWidth, GUIContent(" Stretch width"))
					hollywoodFlareBlurIterations.intValue = EditorGUILayout.IntSlider(" Blur Iterations", hollywoodFlareBlurIterations.intValue, 1, 4)

					EditorGUILayout.PropertyField(lensFlareSaturation, GUIContent(" Saturation"))

					EditorGUILayout.BeginHorizontal()
					EditorGUILayout.PropertyField(flareColorA, GUIContent(" 1st Color"))
					EditorGUILayout.PropertyField(flareColorB, GUIContent(" 2nd Color"))
					EditorGUILayout.EndHorizontal()

					EditorGUILayout.BeginHorizontal()
					EditorGUILayout.PropertyField(flareColorC, GUIContent(" 3rd Color"))
					EditorGUILayout.PropertyField(flareColorD, GUIContent(" 4th Color"))
					EditorGUILayout.EndHorizontal()

				EditorGUILayout.PropertyField(lensFlareVignetteMask, GUIContent(" Mask", "This mask is needed to prevent lens flare artifacts"))

		serObj.ApplyModifiedProperties()
