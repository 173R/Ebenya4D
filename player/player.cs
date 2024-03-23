using Godot;
using System;

public partial class player : CharacterBody3D
{
	
	// Дочерние ноды
	private Node3D _head;
	private Node3D _neck;
	private Camera3D _camera;
	private CollisionShape3D _defaultCollision;
	private CollisionShape3D _crouchCollision;
	private RayCast3D _crouchRayCast;
	
	// States
	private bool _isWalk;
	private bool _isSprint;
	private bool _isCrouch;
	private bool _isFreeLook;
	
	
	// Speed
	private Vector3 _direction = Vector3.Zero;
	
	private const float WalkSpeed = 5.0f;
	private const float SprintSpeed = 7.0f;
	private const float CrouchSpeed = 3.0f;
	private const float LerpSpeed = 10.0f;
	private const float AirLerpSpeed = 1.0f;
	
	private float _currentSpeed = WalkSpeed;

	private float _freeLookAmount = -5f;
	
	// Movement vars
	private const float JumpVelocity = 4.5f;

	private const float CrouchDepth = -0.5f;
	
	
	private const float MouseSense = 0.2f;

	// Get the gravity from the project settings to be synced with RigidBody nodes.
	public float gravity = ProjectSettings.GetSetting("physics/3d/default_gravity").AsSingle();
	
	
	public override void _Ready()
	{
		Input.MouseMode = Input.MouseModeEnum.Captured;
		
		_head = GetNode<Node3D>("neck/head");
		_neck = GetNode<Node3D>("neck");
		_camera = GetNode<Camera3D>("neck/head/Camera3D");
		_defaultCollision = GetNode<CollisionShape3D>("default_collision_shape");
		_crouchCollision = GetNode<CollisionShape3D>("crouch_collision_shape");
		_crouchRayCast = GetNode<RayCast3D>("crouch_raycast");
	}

	public override void _Input(InputEvent @event)
	{
		if (@event is InputEventMouseMotion inputEvent)
		{

			if (_isFreeLook)
			{
				_neck.RotateY(-Mathf.DegToRad(inputEvent.Relative.X * MouseSense));

				
				_neck.Rotation = new Vector3(
					_neck.Rotation.X,
					Mathf.Clamp(_neck.Rotation.Y, Mathf.DegToRad(-120), Mathf.DegToRad(120)),
					_neck.Rotation.Z
				);
			}
			else
			{
				RotateY(-Mathf.DegToRad(inputEvent.Relative.X * MouseSense));	
			}
			
			_head.RotateX(-Mathf.DegToRad(inputEvent.Relative.Y * MouseSense));
			
			var headRotation = _head.Rotation;

			headRotation.X = Mathf.Clamp(
				headRotation.X,
				Mathf.DegToRad(-89),
				Mathf.DegToRad(89)
			);

			_head.Rotation = headRotation;
		}
	}

	public override void _Process(double delta)
	{
		if (Input.IsActionJustPressed("ui_cancel"))
		{
			Input.MouseMode = Input.MouseModeEnum.Visible;
		}
	}

	public override void _PhysicsProcess(double delta)
	{
		var newPosition = _head.Position;
		
		if (Input.IsActionPressed("crouch"))
		{
			_currentSpeed = Mathf.Lerp(_currentSpeed, CrouchSpeed, (float)delta * LerpSpeed);
			
			// Высота головы при пресидании
			newPosition.Y = Mathf.Lerp(newPosition.Y, CrouchDepth, (float)delta * LerpSpeed);
			_head.Position = newPosition;

			// Подмена коллизий
			_defaultCollision.Disabled = true;
			_crouchCollision.Disabled = false;

			_isWalk = false;
			_isSprint = false;
			_isCrouch = true;
		}
		else if (!_crouchRayCast.IsColliding())
		{
			// Подмена коллизий
			_defaultCollision.Disabled = false;
			_crouchCollision.Disabled = true;
			
			// Высота головы в полный рост
			newPosition.Y = Mathf.Lerp(newPosition.Y, 0f, (float)delta * LerpSpeed);
			_head.Position = newPosition;
			
			if (Input.IsActionPressed("sprint"))
			{
				_currentSpeed = Mathf.Lerp(_currentSpeed, SprintSpeed, (float)delta * LerpSpeed);
				
				_isWalk = false;
				_isSprint = true;
				_isCrouch = false;
			} else
			{
				_currentSpeed = Mathf.Lerp(_currentSpeed, WalkSpeed, (float)delta * LerpSpeed);;
				
				_isWalk = true;
				_isSprint = false;
				_isCrouch = false;
			}
		}

		if (Input.IsActionPressed("free_look"))
		{
			_isFreeLook = true;
			_camera.Rotation = new Vector3(
				_camera.Rotation.X,
				_camera.Rotation.Y,
				Mathf.DegToRad(_neck.Rotation.Y * _freeLookAmount)
			);
		}
		else
		{
			_isFreeLook = false;
			
			var newRotation = _neck.Rotation;
			newRotation.Y = Mathf.Lerp(newRotation.Y, 0, (float)delta * LerpSpeed);
			_neck.Rotation = newRotation;
			
			_camera.Rotation = new Vector3(
				_camera.Rotation.X,
				_camera.Rotation.Y,
				Mathf.Lerp(_camera.Rotation.Z, 0, (float)delta * LerpSpeed)
			);
		}
		
		
		var velocity = Velocity;

		// Add the gravity.
		if (!IsOnFloor())
			velocity.Y -= gravity * (float)delta;

		// Handle Jump.
		if (Input.IsActionJustPressed("ui_accept") && IsOnFloor() && !_crouchRayCast.IsColliding())
			velocity.Y = JumpVelocity;
		
		// Get the input direction and handle the movement/deceleration.
		// As good practice, you should replace UI actions with custom gameplay actions.
		var inputDir = Input.GetVector("left", "right", "forward", "backward");
		
		if (IsOnFloor())
			_direction = _direction.Lerp(
				(Transform.Basis * new Vector3(inputDir.X, 0, inputDir.Y)).Normalized(),
				(float)delta * LerpSpeed
			);
		else
			if (inputDir != Vector2.Zero)
				_direction = _direction.Lerp(
					(Transform.Basis * new Vector3(inputDir.X, 0, inputDir.Y)).Normalized(),
					(float)delta * AirLerpSpeed
				);
		
		if (_direction != Vector3.Zero)
		{
			velocity.X = _direction.X * _currentSpeed;
			velocity.Z = _direction.Z * _currentSpeed;
		}
		else
		{
			velocity.X = Mathf.MoveToward(Velocity.X, 0, _currentSpeed);
			velocity.Z = Mathf.MoveToward(Velocity.Z, 0, _currentSpeed);
		}

		Velocity = velocity;
		MoveAndSlide();
	}
}
