import UnityEngine

class LogoShake(MonoBehaviour):
	
	public Speed = 0.03f
	
	// cache for performance
	private tr as Transform
	
	def Awake():
		tr = transform
		
	def Update():
		pingPong = Mathf.PingPong(Time.time * Speed, 0.1f)
		
		tr.localScale.x = 0.2 + pingPong
		tr.localScale.y = 0.1779359 + pingPong