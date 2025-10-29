extends CharacterBody3D

# Player movement settings
@export var speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002

# Player health settings
@export var max_health: int = 100
var health: int

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	# Initialize health
	health = max_health
	
	# Capture mouse for first-person camera
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Print initial health
	print("Player ready! Health: ", health, "/", max_health)

func _input(event: InputEvent) -> void:
	# Handle mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Rotate player left/right
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Rotate camera up/down
		var camera_rotation = -event.relative.y * mouse_sensitivity
		camera.rotation.x = clamp(camera.rotation.x + camera_rotation, -1.5, 1.5)
	
	# Toggle mouse capture with Escape key
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	# Handle movement
	handle_movement(delta)
	
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Move the player
	move_and_slide()

func handle_movement(delta: float) -> void:
	# Reset horizontal velocity
	var input_dir := Vector3.ZERO
	
	# Get input direction
	if Input.is_key_pressed(KEY_W):
		input_dir -= transform.basis.z
	if Input.is_key_pressed(KEY_S):
		input_dir += transform.basis.z
	if Input.is_key_pressed(KEY_A):
		input_dir -= transform.basis.x
	if Input.is_key_pressed(KEY_D):
		input_dir += transform.basis.x
	
	# Normalize input direction to prevent faster diagonal movement
	input_dir = input_dir.normalized()
	
	# Apply movement
	if input_dir != Vector3.ZERO:
		velocity.x = input_dir.x * speed
		velocity.z = input_dir.z * speed
	else:
		# Smooth stop when no input
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	# Handle jumping
	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = jump_velocity

# Health management functions
func take_damage(amount: int) -> void:
	health = max(0, health - amount)
	print("Took ", amount, " damage! Health: ", health, "/", max_health)
	
	if health <= 0:
		die()

func heal(amount: int) -> void:
	health = min(max_health, health + amount)
	print("Healed ", amount, " health! Health: ", health, "/", max_health)

func set_max_health(new_max: int) -> void:
	max_health = new_max
	health = min(health, max_health)
	print("Max health set to: ", max_health)

func get_health_percentage() -> float:
	return float(health) / float(max_health)

func die() -> void:
	print("Player died!")
	# Add death logic here (respawn, game over, etc.)
	
	# Example: respawn with full health
	# health = max_health
	# global_position = Vector3.ZERO

# Debug function to test health system
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				take_damage(10)
			KEY_2:
				heal(10)
			KEY_3:
				set_max_health(max_health + 10)
