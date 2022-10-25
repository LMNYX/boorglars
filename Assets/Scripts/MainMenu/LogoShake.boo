import UnityEngine
import System.Collections

class LogoShake (MonoBehaviour): 
	
	step as single = 0.001
	directionReversed as bool = false

	def Start ():
		StartCoroutine("Shake")
	
	def Update ():
		pass
	
	def Shake() as IEnumerator:
		while true:
			trsc = transform.localScale
			
			if trsc.x > 0.16:
				directionReversed = true
			elif trsc.x < 0.06:
				directionReversed = false
			
			if directionReversed:
				trsc.x -= step
				trsc.y -= step
			else:
				trsc.x += step
				trsc.y += step
			transform.localScale = trsc
			yield WaitForSeconds(0.03)