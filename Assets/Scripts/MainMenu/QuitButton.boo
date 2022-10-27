import UnityEngine

class QuitButton(Button):
	
	override def OnPressed():
		Application.Quit()