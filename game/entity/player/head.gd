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
