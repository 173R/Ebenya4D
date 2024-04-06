extends CharacterBody3D

signal health_changed(new_value: int)

enum state {IDLE, WALK, SPRINT, CROUCH}

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

var health: int = 100
var is_free_look: bool = false
var move_direction: Vector3   = Vector3.ZERO
var gravity                 = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_speed: float    = WALK_SPEED
var free_look_amount: float = -5.0
var current_state = state.IDLE

@onready var head: Node3D = $Neck/Head
@onready var neck: Node3D = $Neck
@onready var camera = $Neck/Head/Camera
@onready var idle_collision = $IdleCollision
@onready var crouch_collision = $CrouchCollision
@onready var crouch_raycast = $CrouchRaycast

@onready var muzzle_flash: GPUParticles3D = $Neck/Head/Camera/Rifle/MuzzleFlash
@onready var shoot_ray_cast: RayCast3D = $Neck/Head/Camera/RayCast3D

@onready var anim_player = $AnimationPlayer


func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if not is_multiplayer_authority(): return
	camera.current = true

	# Возможно стоит перенести
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Перехватывает событие только в том случае если его никто до этого ещё не перехватил
func _unhandled_input(event):
	if not is_multiplayer_authority(): return

	if event is InputEventMouseMotion:
		if is_free_look:
			neck.rotate_y(-deg_to_rad(event.relative.x * MOUSE_SENSE))
			neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-120), deg_to_rad(120))
		else:
			rotate_y(-deg_to_rad(event.relative.x * MOUSE_SENSE))
	
		head.rotate_x(-deg_to_rad(event.relative.y * MOUSE_SENSE))

		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

	if Input.is_action_just_pressed("use") \
		and anim_player.current_animation != "shoot":
			play_shoot_effect.rpc()

			#shoot_ray_cast.enabled = true

			if shoot_ray_cast.is_colliding():
				var hit_player = shoot_ray_cast.get_collider()
				hit_player.recive_damage.rpc_id(hit_player.get_multiplayer_authority())

			#shoot_ray_cast.enabled = false

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta):
	if not is_multiplayer_authority(): return

	#if shoot_ray_cast.is_colliding():
	#	if shoot_ray_cast.get_collider() is CharacterBody3D and get_multiplayer_authority() == 1:
	#		print("AAA")

	if Input.is_action_pressed("crouch"):

		current_speed = lerp(current_speed, CROUCH_SPEED, delta * LERP_SPEED)

		# Изменяем высоту головы при пресидации
		head.position.y = lerp(head.position.y, CROUCH_DEPTH, delta * LERP_SPEED)

		# Подмена коллизий
		idle_collision.disabled = true
		crouch_collision.disabled = false
		current_state = state.CROUCH

	elif !crouch_raycast.is_colliding():
		idle_collision.disabled = false
		crouch_collision.disabled = true

		head.position.y = lerp(head.position.y, 0.0, delta * LERP_SPEED)

		if (Input.is_action_pressed("sprint")):
			current_speed = lerp(current_speed, SPRINT_SPEED, float(delta) * LERP_SPEED)

			current_state = state.SPRINT
		else:
			current_speed = lerp(current_speed, WALK_SPEED, delta * LERP_SPEED)

			current_state = state.WALK

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
		move_direction = move_direction.lerp(
			(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),
			delta * LERP_SPEED
		)
	else:
		if input_dir != Vector2.ZERO:
			move_direction = move_direction.lerp(
				(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),
				delta * AIR_LERP_SPEED
			)

	# ЗАлупка
	if anim_player.current_animation == "shoot":
		pass
	elif input_dir != Vector2.ZERO and is_on_floor():
		anim_player.play("move_2")
	else:
		anim_player.play("idle")
	#

	if move_direction != Vector3.ZERO:
		velocity.x = move_direction.x * current_speed
		velocity.z = move_direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

@rpc("call_local")
func play_shoot_effect():
	print(is_multiplayer_authority())
	print("SHOOOT \n")
	anim_player.stop()
	anim_player.play("shoot")
	muzzle_flash.restart()
	muzzle_flash.emitting = true

@rpc("any_peer")
func recive_damage():
	health -= 30
	if health < 1:
		health = 100
		position = Vector3.ZERO
	health_changed.emit(health)

func _on_animation_player_animation_finished(anim_name:StringName):
	if anim_name == "shoot":
		anim_player.play("idle")
