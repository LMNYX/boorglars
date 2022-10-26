import UnityEngine

class PlayButton(Button):
	
	override def OnPressed():
		Debug.Log("Specific logic to PlayButton")