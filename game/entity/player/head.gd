extends RigidBody2D


const RECALL_IMPULSE := 8000.0


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
	if abs(linear_velocity) < Vector2(10, 10):
		#print("stationary")
		set_collision_layer_value(5, true)
		set_collision_layer_value(4, false)
	else:
		#print("moving")
		set_collision_layer_value(5, false)
		set_collision_layer_value(4, true)
	
	$Node.rotation = -rotation


func _on_enter_rolling_body_entered(body: Node2D) -> void:
	
	var is_on_floor = $Node/FloorCast.is_colliding()
	
	if body.is_in_group(Groups.PLAYER) and is_on_floor:
		Signals.initiate_rolling.emit(global_position)
		queue_free()
