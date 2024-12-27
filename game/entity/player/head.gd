extends RigidBody2D


const TORQUE := 8000.0
const LERP_DELTA := 10.0

var is_active_character := false
var is_switch_blocked := false

func _ready():
	add_to_group(Groups.PLAYER)
	add_to_group(Groups.HAS_WEIGHT)
	add_to_group(Groups.PICKUP)
	add_to_group(Groups.HEAD)
	
	Signals.switch_active_character.connect(_on_switch_active_character)


func _on_switch_active_character(character: Constants.CHARACTER):
	if not is_switch_blocked:
		if character == Constants.CHARACTER.HEAD:
			is_switch_blocked = true
			is_active_character = true
			$Camera2D.make_current()
			$Timers/SwitchBlockTimer.start()
		else:
			is_active_character = false


func _physics_process(delta):
	if is_active_character:
		var direction = Input.get_axis("move_left", "move_right")
		
		if direction:
			if direction * angular_velocity < 0:
				constant_torque = move_toward(direction * TORQUE * 2, direction * TORQUE, LERP_DELTA)
			else:
				constant_torque = move_toward(constant_torque, direction * TORQUE, LERP_DELTA)
		else:
			constant_torque = 0.0
		
		if not is_switch_blocked and Input.is_action_just_pressed("switch"):
			constant_torque = 0.0
			is_switch_blocked = true
			is_active_character = false
			$Timers/SwitchBlockTimer.start()
			Signals.switch_active_character.emit(Constants.CHARACTER.PLAYER)


func _on_switch_block_timer_timeout():
	is_switch_blocked = false
