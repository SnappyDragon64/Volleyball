extends CharacterBody2D

const SPEED = 200.0
const HEADLESS_SPEED = 400.0
const JUMP_VELOCITY = -400.0

enum State {DEFAULT, HEADLESS, ITEM, ROLLING}

@onready var volley_scene := preload("res://game/entity/player/volley.tscn")
@onready var volley_instance: RigidBody2D

var current_state: State = State.DEFAULT
var controller_mode := false

func _ready():
	volley_instance = volley_scene.instantiate()
	get_parent().call_deferred("add_child", volley_instance)
	volley_instance.ready.connect(_on_volley_ready)


func _on_volley_ready():
	$RemoteTransform2D.set_remote_node(volley_instance.get_path())
	volley_instance.get_node("CollisionShape2D").set_disabled(true)
	volley_instance.set_freeze_enabled(true)


func _input(event):
	if event is InputEventKey:
		controller_mode = false
	elif event is InputEventJoypadButton:
		controller_mode = true
	elif event is InputEventMouseButton:
		controller_mode = false


func _physics_process(delta):
	match current_state:
		State.DEFAULT:
			_default_physics_process(delta)
		State.HEADLESS:
			_headless_physics_process(delta)
		State.ITEM:
			_item_physics_process(delta)
		State.HEADLESS:
			_default_physics_process(delta)


func _default_physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	var direction = Input.get_axis("move_left", "move_right")
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if controller_mode:
		var controller_direction = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
		
		if not controller_direction.is_zero_approx():
			var angle = controller_direction.angle()
			$RemoteTransform2D/Marker2D.set_rotation(angle)
			$RemoteTransform2D/Marker2D/Icon.set_visible(true)
			
			if Input.is_action_just_pressed("shoot"):
				shoot(controller_direction)
		else:
			$RemoteTransform2D/Marker2D/Icon.set_visible(false)
	else:
		var mouse_direction = get_global_mouse_position() - $RemoteTransform2D/Marker2D.get_global_transform().origin
		
		if Input.is_action_just_pressed("shoot"):
			shoot(mouse_direction)

	move_and_slide()


func shoot(direction_vector: Vector2):
	direction_vector = direction_vector.normalized() * 10
	$RemoteTransform2D.set_remote_node("")
	volley_instance.get_node("CollisionShape2D").set_disabled(false)
	volley_instance.set_freeze_enabled(false)
	volley_instance.add_constant_central_force(direction_vector)
	current_state = State.HEADLESS


func _headless_physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	var direction = Input.get_axis("move_left", "move_right")
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()


func _item_physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	var direction = Input.get_axis("move_left", "move_right")
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()


func _rolling_physics_process(delta):
	pass
