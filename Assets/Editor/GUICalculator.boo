import UnityEditor
import UnityEngine

class GUICalculator(EditorWindow):
	
	static referenceWidth = 0.562
	static referenceHeight = 1.0
	
	private width = 100
	private height = 100
	
	private scaleX = 1.0f
	private scaleY = 1.0f
	
	private multiplier = 1.0f
	
	private resultX = 0.0f
	private resultY = 0.0f
	
	[MenuItem("Tools/GUI Calculator")]
	static def ShowWindow():
		EditorWindow.GetWindow(typeof(GUICalculator), false, "GUI Calculator", true)
		
	def OnGUI():
		GUILayout.Label("Size", EditorStyles.boldLabel)
		
		width = EditorGUILayout.IntField("Width", width)
		height = EditorGUILayout.IntField("Height", height)
				
		GUILayout.Label("Scale", EditorStyles.boldLabel)
		
		EditorGUILayout.BeginHorizontal()
		EditorGUIUtility.labelWidth = 16
		scaleX = EditorGUILayout.FloatField("X", scaleX)
		scaleY = EditorGUILayout.FloatField("Y", scaleY)
		EditorGUIUtility.labelWidth = 0
		EditorGUILayout.EndHorizontal()
		
		GUILayout.Label("Additional", EditorStyles.boldLabel)
		multiplier = EditorGUILayout.FloatField("Multiplier", multiplier)
		
		GUILayout.Label("Result", EditorStyles.boldLabel)
		
		EditorGUILayout.BeginHorizontal()
		GUILayout.Label("X")
		EditorGUILayout.SelectableLabel(resultX.ToString(), EditorStyles.textField, GUILayout.Height(EditorGUIUtility.singleLineHeight))
		GUILayout.Label("Y")
		EditorGUILayout.SelectableLabel(resultY.ToString(), EditorStyles.textField, GUILayout.Height(EditorGUIUtility.singleLineHeight))
		EditorGUILayout.EndHorizontal()
		
		if GUILayout.Button("Calculate"):
			Calculate()
			
		if Selection.activeTransform and Selection.activeTransform.GetComponent[of GUITexture]() and GUILayout.Button("Apply"):
			Calculate()
			Apply()
			
	def Calculate():
		resultX = width / height * referenceWidth * scaleX * multiplier
		resultY = referenceHeight * scaleY * multiplier
		
	def Apply():
		if not Selection.activeTransform or not Selection.activeTransform.GetComponent[of GUITexture]():
			return
		
		Selection.activeTransform.localScale.x = resultX
		Selection.activeTransform.localScale.y = resultY
		
	def OnSelectionChange():
		if not Selection.activeTransform or not Selection.activeTransform.GetComponent[of GUITexture]():
			return
		
		width = Selection.activeTransform.GetComponent[of GUITexture]().texture.width
		height = Selection.activeTransform.GetComponent[of GUITexture]().texture.height
		
		Calculate()
		Repaint()
		
	def OnInspectorUpdate():
		Repaint()