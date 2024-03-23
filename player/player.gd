extends CharacterBody3D


@onready var head: Node3D = $neck/head
@onready var neck: Node3D = $neck
@onready var camera = $neck/head/Camera3D
@onready var default_collision_shape = $default_collision_shape
@onready var crouch_collision_shape = $crouch_collision_shape
@onready var crouch_raycast = $crouch_raycast

# Инвентарь
@export var invetory_data: InventoryData
signal toggle_inventory()

# Controls
const MOUSE_SENSE: float = 0.2

# Speed
const WALK_SPEED: float   = 5.0
const SPRINT_SPEED: float  = 7.0
const CROUCH_SPEED: float  = 3.0
const JUMP_VELOCITY: float = 4.5
const CROUCH_DEPTH: float   = -0.5
const LERP_SPEED: float     = 10.0
const AIR_LERP_SPEED: float = 1.0


# States
var is_walk: bool
var is_sprint: bool
var is_crouch: bool
var is_free_look: bool


var direction: Vector3   = Vector3.ZERO
var gravity                 = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_speed: float    = WALK_SPEED
var free_look_amount: float = -5.0


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Перехватывает событие только в том случае если его никто до этого ещё не перехватил
func _unhandled_input(_event):
	if Input.is_action_just_pressed("inventory"):
		toggle_inventory.emit()

func _input(event):
	if event is InputEventMouseMotion:
		if is_free_look:
			neck.rotate_y(-deg_to_rad(event.relative.x * MOUSE_SENSE))
			neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-120), deg_to_rad(120))
		else:
			rotate_y(-deg_to_rad(event.relative.x * MOUSE_SENSE))
	
		head.rotate_x(-deg_to_rad(event.relative.y * MOUSE_SENSE))

		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta):

	if Input.is_action_pressed("crouch"):
		current_speed = lerp(current_speed, CROUCH_SPEED, delta * LERP_SPEED)

		# Изменяем высоту головы при пресидации
		head.position.y = lerp(head.position.y, CROUCH_DEPTH, delta * LERP_SPEED)

		# Подмена коллизий
		default_collision_shape.disabled = true
		crouch_collision_shape.disabled = false

		is_walk = false
		is_sprint = false
		is_crouch = true
	elif !crouch_raycast.is_colliding():
		default_collision_shape.disabled = false
		crouch_collision_shape.disabled = true

		head.position.y = lerp(head.position.y, 0.0, delta * LERP_SPEED)

		if (Input.is_action_pressed("sprint")):
			current_speed = lerp(current_speed, SPRINT_SPEED, float(delta) * LERP_SPEED)

			is_walk = false
			is_sprint = true
			is_crouch = false
		else:
			current_speed = lerp(current_speed, WALK_SPEED, delta * LERP_SPEED)

			is_walk = true
			is_sprint = false
			is_crouch = false

	if (Input.is_action_pressed("free_look")):
		is_free_look = true
		camera.rotation.z = deg_to_rad(neck.rotation.y * free_look_amount)
	else:
		is_free_look = false
		neck.rotation.y = lerp(neck.rotation.y, 0.0, delta * LERP_SPEED)
		camera.rotation.z = lerp(camera.rotation.z, 0.0, delta * LERP_SPEED)

	# Гравитация
	if !is_on_floor():
		velocity.y -= gravity * delta

	# Прыжок
	if Input.is_action_just_pressed("ui_accept") && is_on_floor() && !crouch_raycast.is_colliding():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	if is_on_floor():
		direction = direction.lerp(
			(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),
			delta * LERP_SPEED
		)
	else:
		if input_dir != Vector2.ZERO:
			direction = direction.lerp(
				(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),
				delta * AIR_LERP_SPEED
			)

	if direction != Vector3.ZERO:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
