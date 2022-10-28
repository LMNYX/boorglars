import UnityEngine

[RequireComponent(GUITexture)]
class Button(MonoBehaviour):

	public DefaultColor = Color(0.5, 0.5, 0.5, 0.5)
	public SelectedColor = Color(0.375, 0.375, 0.375, 0.5)
	public PressedColor = Color(0.25, 0.25, 0.25, 0.5)

	private isSelected = false
	private isPressed = false

	private buttonGuiTexture as GUITexture

	virtual def OnPressed():
		Debug.Log("$(transform.name) is pressed!")

	def Awake():
		buttonGuiTexture = gameObject.GetComponent[of GUITexture]()

	def Update():
		if not isSelected and not isPressed:
			buttonGuiTexture.color = DefaultColor

		if isSelected:
			buttonGuiTexture.color = SelectedColor

		if isPressed:
			buttonGuiTexture.color = PressedColor

	def OnMouseEnter():
		isSelected = true

	def OnMouseExit():
		isSelected = false
		isPressed = false

	def OnMouseDown():
		isPressed = true
		OnPressed()

	// lmao
	def OnMouseUpAsButton():
		isPressed = false