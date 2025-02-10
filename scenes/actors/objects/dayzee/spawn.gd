extends EnemySpawnerBase


export var is_stationary: bool = false
export var rainbow: bool = false
export var color: = Color(1, 1, 1)

func get_enemy_properties() -> Array:
	return [
		"is_stationary",
		"color",
		"rainbow"
	]
