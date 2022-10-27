import UnityEngine

[RequireComponent(CapsuleCollider)]
[RequireComponent(Rigidbody)]
class Character(MonoBehaviour): 

	public MovementSpeed = 4.0f
	public CrouchMovementSpeed = 2.0f
	public AccelerationSpeed = 10.0f
	public JumpForce = 400.0f
	
	public MouseSensitivity = 3.0f // todo: move to settings
	
	private isGrounded as bool
	
	private directionVector as Vector3
	private jumpInput as bool
	
	private rotation as Vector2
	private previousY as single
	private movementForce as Vector3

	private overlapMask = 19
	
	private characterCollider as CapsuleCollider
	private characterRigidbody as Rigidbody
	private characterCamera as Camera

	def Awake():
		characterCollider = GetComponent[of CapsuleCollider]()
		characterRigidbody = GetComponent[of Rigidbody]()
		characterCamera = Camera.main
		
	def Update():
		HandleMoveInput()
		HandleLookInput()
		
	def HandleMoveInput():
		// TERNARY CONDITIONAL OPERATOR IN BOO WTF
		left = (1 if Input.GetKey(KeyCode.A) else 0)
		right = (1 if Input.GetKey(KeyCode.D) else 0)
		front = (1 if Input.GetKey(KeyCode.W) else 0)
		back = (1 if Input.GetKey(KeyCode.S) else 0)
		
		directionVector = Vector3.ClampMagnitude(Vector3(-left + right, 0, front - back), 1.0f)
		jumpInput = Input.GetKey(KeyCode.Space)
		
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
		hasGround = Physics.CheckSphere(transform.TransformPoint(groundCheckerPosition), 0.4f, overlapMask)
		isGrounded = Mathf.Abs(characterRigidbody.velocity.y - previousY) < 0.1f and hasGround
		previousY = characterRigidbody.velocity.y
		
	def HandleMovementForce():
		characterRigidbody.velocity = Vector3.ClampMagnitude(characterRigidbody.velocity, 150.0f)
		
		movementDirection = transform.forward * directionVector.z
		movementDirection += transform.right * directionVector.x

		speed = MovementSpeed

		if characterCollider.height < 2.0f:
			speed = CrouchMovementSpeed
			
		movementForce = Vector3.ClampMagnitude(movementDirection, 1.0f) * speed
		
	def HandleCrouch():
		crouchSpeed = 4.0f
		ceilCheckerPosition = Vector3(0.0f, 0.7f, 0.0f)
		
		if Input.GetKey(KeyCode.LeftControl):
			if characterCollider.height > 1.2f:
				characterCollider.height -= crouchSpeed * Time.deltaTime
				transform.position.y -= crouchSpeed * Time.deltaTime
			if characterCollider.center.y < 0.4f:
				characterCollider.center.y += crouchSpeed * Time.deltaTime / 2
		elif not Physics.CheckSphere(transform.TransformPoint(ceilCheckerPosition), characterCollider.radius * 0.95f, overlapMask):
			if characterCollider.height < 2.0f:
				characterCollider.height += crouchSpeed * Time.deltaTime
				transform.position.y += crouchSpeed * Time.deltaTime
			if characterCollider.center.y > 0:
				characterCollider.center.y -= crouchSpeed * Time.deltaTime / 2
				
		characterCollider.height = Mathf.Clamp(characterCollider.height, 1.2f, 2.0f)
		characterCollider.center.y = Mathf.Clamp(characterCollider.center.y, 0, 0.4f)
		
	def HandleJump():
		if jumpInput and isGrounded:
			characterRigidbody.AddForce(JumpForce * characterRigidbody.mass * Vector3.up)
			
	def HandleMovement():
		if (isGrounded):
			characterRigidbody.velocity = Vector3.Lerp(characterRigidbody.velocity, movementForce, AccelerationSpeed * Time.deltaTime)
		else:
			characterRigidbody.velocity = Vector3.ClampMagnitude(characterRigidbody.velocity + movementForce * Time.deltaTime, characterRigidbody.velocity.magnitude)