extends Node


# PLAYER
signal recall_head(player_global_position: Vector2)

#HEAD
signal initiate_rolling(head_rotation: float)

# EVENT
signal event(id: int)
