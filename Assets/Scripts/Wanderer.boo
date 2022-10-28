import UnityEngine

class Wanderer(MonoBehaviour):

	public IsWandering as bool

	goal as Vector3

	[Range(0, 30)] public delayBetweenNavigations as single
	[Range(0, 30)] public delayBeforeFirstNavigation as single
	[Range(1, 2000)] public radius as single

	PauseTime as single

	agent as NavMeshAgent

	def Start():
		agent = GetComponent[of NavMeshAgent]()
		PauseTime = delayBeforeFirstNavigation

	def Update():
		if Time.time < PauseTime:
			return

		if agent.remainingDistance <= 0.1 and IsWandering:
			PauseTime = Time.time + delayBetweenNavigations
			SetDestination(GetRandomNavMeshPosition(transform.position, radius, -1))

	def SetDestination(newGoal as Vector3):
		goal = newGoal
		agent.destination = goal

	def GetRandomNavMeshPosition(origin as Vector3, distance as single, layerMask as int) as Vector3:
		randomDirection = Random.insideUnitSphere * distance
		navMeshHit as NavMeshHit
		NavMesh.SamplePosition(origin + randomDirection, navMeshHit, distance, layerMask)

		return navMeshHit.position