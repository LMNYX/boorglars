import UnityEngine

[RequireComponent(CapsuleCollider)]
[RequireComponent(Rigidbody)]
class Character(MonoBehaviour): 

	public MovementSpeed = 6.0f
	public AccelerationSpeed = 10.0f
	public MaximumSpeed = 150.0f

	public JumpForce = 400.0f

	public MouseSensitivity = 3.0f
	
	private rotation = Vector2.zero

	private isGrounded as bool

	private crouchRaycast as bool
	private currentColliderCenterY as single
	private defaultHeight = 2.0f
	private crouchHeight = 1.2f
	private crouchSpeed = 4.0f
	private crouchColliderCenterY = 0.4f

	private previousY as single
	private directionVector as Vector3
	private movementForce as Vector3

	private overlapMask as LayerMask = 19
	private groundCheckerPosition as Vector3
	private groundCheckerRadius = 0.4f
	
	private ceilCheckerPosition = Vector3(0.0f, 1.0f, 0.0f)
	
	private characterCollider as CapsuleCollider
	private characterRigidbody as Rigidbody
	private characterCamera as Camera

	def Awake():
		characterCollider = GetComponent[of CapsuleCollider]()
		characterRigidbody = GetComponent[of Rigidbody]()
		characterCamera = Camera.main

	def Start():
		pass
	
	def Update():
		HandleMoveInput()
		HandleLookInput()
		
	def HandleMoveInput():
		left = 0
		right = 0
		front = 0
		back = 0
		
		if Input.GetKey(KeyCode.A):
			left = 1
		if Input.GetKey(KeyCode.D):
			right = 1
		if Input.GetKey(KeyCode.W):
			front = 1
		if Input.GetKey(KeyCode.S):
			back = 1
		
		directionVector = Vector3.ClampMagnitude(Vector3(-left + right, 0, front - back), 1.0f)
		
	def HandleLookInput():
		rotation.y += Input.GetAxis("Mouse X") * MouseSensitivity
		rotation.x += -Input.GetAxis("Mouse Y") * MouseSensitivity
		rotation.x = Mathf.Clamp(rotation.x, -90f, 90f)
		transform.eulerAngles = Vector2(0, rotation.y)
		characterCamera.transform.localRotation = Quaternion.Euler(rotation.x, 0, 0)
		
	def FixedUpdate():
		HandleGround()
		HandleMovementForce()
		HandleCrouch()
		HandleJump()
		HandleMovement()
		
	def HandleGround():
		groundCheckerPosition = Vector3(0, -0.65f + (1.2f - (characterCollider.height - 0.8f)), 0)
		hasGround = Physics.CheckSphere(transform.TransformPoint(groundCheckerPosition), groundCheckerRadius, overlapMask)
		isGrounded = Mathf.Abs(characterRigidbody.velocity.y - previousY) < 0.1f and hasGround
		previousY = characterRigidbody.velocity.y
		
	def HandleMovementForce():
		characterRigidbody.velocity = Vector3.ClampMagnitude(characterRigidbody.velocity, MaximumSpeed)
		
		movementDirection = transform.forward * directionVector.z
		movementDirection += transform.right * directionVector.x

		movementForce = Vector3.ClampMagnitude(movementDirection, 1.0f) * MovementSpeed
		
	def HandleCrouch():
		if Input.GetKey(KeyCode.LeftControl):
			if characterCollider.height > crouchHeight:
				characterCollider.height -= crouchSpeed * Time.deltaTime
				transform.position.y -= crouchSpeed * Time.deltaTime
			if currentColliderCenterY < crouchColliderCenterY:
				currentColliderCenterY += crouchSpeed * Time.deltaTime / 2
		else:
			if Physics.CheckSphere(transform.TransformPoint(ceilCheckerPosition), characterCollider.radius * 0.95f, overlapMask):
				if characterCollider.height < defaultHeight:
					characterCollider.height += crouchSpeed * Time.deltaTime
				if currentColliderCenterY > 0:
					currentColliderCenterY -= crouchSpeed * Time.deltaTime / 2
				
		characterCollider.height = Mathf.Clamp(characterCollider.height, crouchHeight, defaultHeight)

		currentColliderCenterY = Mathf.Clamp(currentColliderCenterY, 0, crouchColliderCenterY)
		characterCollider.center.y = currentColliderCenterY
		
	def HandleJump():
		if Input.GetKeyDown(KeyCode.Space) and isGrounded:
			characterRigidbody.AddForce(JumpForce * characterRigidbody.mass * Vector3.up)
			
	def HandleMovement():
		if (isGrounded):
			characterRigidbody.velocity = Vector3.Lerp(characterRigidbody.velocity, movementForce, AccelerationSpeed * Time.deltaTime)
		else:
			characterRigidbody.velocity = Vector3.ClampMagnitude(characterRigidbody.velocity + movementForce * Time.deltaTime, characterRigidbody.velocity.magnitude)