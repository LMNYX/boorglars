import UnityEngine

class Wanderer (MonoBehaviour): 

	public IsWandering as bool

	goal as Vector3
	
	[Range(0,30)] public delayBetweenNavigations as single
	[Range(0,30)] public delayBeforeFirstNavigation as single
	[Range(1,2000)] public radius as single
	
	PauseTime as single = 0
	
	agent as NavMeshAgent

	def Start ():
		agent = GetComponent[of NavMeshAgent]()
		PauseTime = delayBeforeFirstNavigation
		
	def Update ():
		if(Time.time < PauseTime):
			return
		if(agent.remainingDistance <= 0.1 and IsWandering):
			PauseTime = Time.time + delayBetweenNavigations
			SetDestination(RandomNavMeshPosition(transform.position, radius, -1))
	
	def SetDestination(newgoal as Vector3):
		goal = newgoal
		agent.destination = goal
	
	def RandomNavMeshPosition(origin as Vector3, distance as single, layermask as int):
		randomDirection as Vector3 = UnityEngine.Random.insideUnitSphere * distance
		randomDirection += origin
		navHit as NavMeshHit
		NavMesh.SamplePosition(randomDirection, navHit, distance, layermask)
		
		return navHit.position