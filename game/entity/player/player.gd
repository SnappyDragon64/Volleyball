extends CharacterBody2D


const SPEED := 200.0
const DEFAULT_SPEED_MULTIPLIER := 1.0
const HEADLESS_SPEED_MULTIPLIER := 2.0
const ROLLING_SPEED_MULTIPLIER := 1.5
const ANGULAR_VELOCITY := 9.375
const JUMP_VELOCITY := -400.0
const THROW_IMPULSE := 500.0

enum State {DEFAULT, HEADLESS, ITEM}

@onready var head_scene := preload("res://game/entity/player/head.tscn")

@export var current_state := State.DEFAULT
@export var controller_mode := false

var is_active_character := true
var is_switch_blocked := false


func _ready():
	add_to_group(Groups.PLAYER)
	add_to_group(Groups.HAS_WEIGHT)
	
	Signals.switch_active_character.connect(_on_switch_active_character)


func _on_switch_active_character(character: Constants.CHARACTER):
	if not is_switch_blocked:
		if character == Constants.CHARACTER.PLAYER:
			is_switch_blocked = true
			is_active_character = true
			$Camera2D.make_current()
			$Timers/SwitchBlockTimer.start()
		else:
			is_active_character = false


func _input(event: InputEvent):
	if event is InputEventKey or event is InputEventMouseButton:
		controller_mode = false
		$CrosshairOrigin.set_visible(false)
	elif event is InputEventJoypadButton:
		controller_mode = true


func change_state(new_state: State):
	match new_state:
		State.DEFAULT:
			add_to_group(Groups.HAS_WEIGHT)
			$HeadCollider.set_deferred("disabled", false)
			$Model/HeadModel.set_visible(true)
		State.HEADLESS:
			remove_from_group(Groups.HAS_WEIGHT)
			$HeadCollider.set_deferred("disabled", true)
			$Model/HeadModel.set_visible(false)
		State.ITEM:
			add_to_group(Groups.HAS_WEIGHT)
	
	current_state = new_state


func _physics_process(delta: float):
	match current_state:
		State.DEFAULT:
			_default_physics_process(delta)
		State.HEADLESS:
			_headless_physics_process(delta)
		State.ITEM:
			_item_physics_process(delta)


func _default_physics_process(delta: float):
	apply_gravity(delta)
	
	if is_active_character:
		enable_movement(DEFAULT_SPEED_MULTIPLIER)
		enable_yeet()
		
	move_and_slide()


func _headless_physics_process(delta: float):
	apply_gravity(delta)
	
	if is_active_character:
		enable_movement(HEADLESS_SPEED_MULTIPLIER)
		enable_grab()
		enable_character_switch()
	
	move_and_slide()


func _item_physics_process(delta: float):
	apply_gravity(delta)
	
	if is_active_character:
		enable_movement(DEFAULT_SPEED_MULTIPLIER)
		enable_character_switch()
	
	move_and_slide()


func apply_gravity(delta: float):
	if not is_on_floor():
		velocity += get_gravity() * delta


func enable_movement(multiplier: float):
	var direction = Input.get_axis("move_left", "move_right")
	
	if direction:
		velocity.x = direction * SPEED * multiplier
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	

func enable_yeet():
	if controller_mode:
		var controller_direction = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
		
		if not controller_direction.is_zero_approx():
			var angle = controller_direction.angle()
			$CrosshairOrigin.set_rotation(angle)
			$CrosshairOrigin.set_visible(true)
			
			if Input.is_action_just_pressed("yeet"):
				check_and_yeet(controller_direction)
		else:
			$CrosshairOrigin.set_visible(false)
	else:
		var mouse_direction = get_global_mouse_position() - $CrosshairOrigin.get_global_transform().origin
		check_and_yeet(mouse_direction)


func check_and_yeet(direction_vector: Vector2):
	if Input.is_action_just_pressed("yeet"):
		if direction_vector.y >= 0:
			direction_vector.y = 0
		change_state(State.HEADLESS)
		$CrosshairOrigin.set_visible(false)
		
		var head_instance = head_scene.instantiate()
		
		var crosshair_origin_global_position = $CrosshairOrigin.get_global_position()
		head_instance.set_global_position(crosshair_origin_global_position)
		
		direction_vector = direction_vector.normalized() * THROW_IMPULSE
		head_instance.apply_central_impulse(direction_vector)
		# TODO: Add player's velocity to the head?
		
		call_deferred("add_sibling", head_instance)


func enable_grab():
	if Input.is_action_just_pressed("grab"):
		for body: PhysicsBody2D in $InteractionArea.get_overlapping_bodies():
			if body.is_in_group(Groups.HEAD):
				body.set_process_mode(ProcessMode.PROCESS_MODE_DISABLED)
				body.queue_free()
				change_state(State.DEFAULT)


func enable_character_switch():
	if not is_switch_blocked and Input.is_action_just_pressed("switch"):
		is_switch_blocked = true
		is_active_character = false
		$Timers/SwitchBlockTimer.start()
		Signals.switch_active_character.emit(Constants.CHARACTER.HEAD)


func _on_switch_block_timer_timeout():
	is_switch_blocked = false
