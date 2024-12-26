extends RigidBody2D


const RECALL_IMPULSE := 8000.0
const ROLL_TORQUE_IMPULSE_MULTIPLIER := 10.0
const ROLL_IMPULSE_MULTIPLIER := 1.0

var roll_flag := false
var roll_direction := 0.0


func _ready():
	add_to_group(Groups.PLAYER)
	add_to_group(Groups.HAS_WEIGHT)
	add_to_group(Groups.PICKUP)
	add_to_group(Groups.HEAD)
	
	Signals.recall_head.connect(_on_recall_head)


func _on_recall_head(player_global_position: Vector2):
	var recall_direction = player_global_position - get_global_position()
	recall_direction = recall_direction.normalized()
	var recall_magnitude = recall_direction.x * RECALL_IMPULSE
	apply_torque_impulse(recall_magnitude)


func _physics_process(delta: float) -> void:
	if roll_flag:
		apply_torque_impulse(ROLL_TORQUE_IMPULSE_MULTIPLIER * roll_direction)
		apply_central_impulse(Vector2(ROLL_IMPULSE_MULTIPLIER * roll_direction, 0))
		roll_flag = false
	
	$RotationPivot.rotation = -rotation


func _on_enter_rolling_body_entered(body: Node2D) -> void:
	var is_on_floor = $RotationPivot/FloorCast.is_colliding()
	
	if body.is_in_group(Groups.PLAYER) and body.get_velocity().y <= 0 and is_on_floor:
		Signals.initiate_rolling.emit(rotation)
		queue_free()
