extends CharacterBody3D

# Player movement settings
@export var speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002

# Camera rotation settings
@export var camera_rotation_speed: float = 2.0
@export var max_camera_angle: float = 89.0  # Degrees

# Player health settings
@export var max_health: int = 100
var health: int

# Camera variables
var camera_x_rotation: float = 0.0

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera: Camera3D = $Camera3D
@onready var camera_pivot: Node3D = $CameraPivot

func _ready() -> void:
	# Initialize health
	health = max_health
	
	# Create camera pivot if it doesn't exist
	if not has_node("CameraPivot"):
		var pivot = Node3D.new()
		pivot.name = "CameraPivot"
		add_child(pivot)
		camera_pivot = pivot
		camera.reparent(pivot)
	
	# Capture mouse for first-person camera
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Print initial health
	print("Player ready! Health: ", health, "/", max_health)

func _input(event: InputEvent) -> void:
	# Handle mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Rotate player left/right (Y-axis)
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Rotate camera up/down (X-axis)
		var delta_rotation = -event.relative.y * mouse_sensitivity
		camera_x_rotation += delta_rotation
		
		# Clamp camera rotation to prevent over-rotation
		camera_x_rotation = clamp(camera_x_rotation, 
			-deg_to_rad(max_camera_angle), 
			deg_to_rad(max_camera_angle))
		
		# Apply camera rotation to pivot
		camera_pivot.rotation.x = camera_x_rotation
	
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
	
	# Handle camera rotation with keyboard (optional - for gamepad support)
	handle_keyboard_camera_rotation(delta)
	
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

func handle_keyboard_camera_rotation(delta: float) -> void:
	# Optional: Camera rotation with keyboard (QE keys)
	var rotation_input := 0.0
	
	if Input.is_key_pressed(KEY_Q):
		rotation_input += 1.0
	if Input.is_key_pressed(KEY_E):
		rotation_input -= 1.0
	
	if rotation_input != 0.0:
		rotate_y(rotation_input * camera_rotation_speed * delta)
	
	# Optional: Camera look up/down with keys (R/F keys)
	var vertical_rotation_input := 0.0
	
	if Input.is_key_pressed(KEY_R):
		vertical_rotation_input += 1.0
	if Input.is_key_pressed(KEY_F):
		vertical_rotation_input -= 1.0
	
	if vertical_rotation_input != 0.0:
		camera_x_rotation += vertical_rotation_input * camera_rotation_speed * delta
		camera_x_rotation = clamp(camera_x_rotation, 
			-deg_to_rad(max_camera_angle), 
			deg_to_rad(max_camera_angle))
		camera_pivot.rotation.x = camera_x_rotation

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

# Function to reset camera rotation
func reset_camera_rotation() -> void:
	camera_x_rotation = 0.0
	camera_pivot.rotation.x = 0.0
	rotation.y = 0.0

# Function to get current camera angles (in degrees)
func get_camera_angles() -> Vector2:
	return Vector2(rad_to_deg(camera_x_rotation), rad_to_deg(rotation.y))

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
			KEY_4:
				reset_camera_rotation()
				print("Camera rotation reset")
