import UnityEngine

class QuitButton(Button):
	
	override def OnPressed():
		Debug.Log("Specific logic to QuitButton")