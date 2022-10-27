import UnityEngine

class PlayButton(Button):
	
	override def OnPressed():
		Application.LoadLevel("ReferenceScene")