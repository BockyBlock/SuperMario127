extends EnemyStopState


# onready var colored_sprite: AnimatedSprite = $"%RecolorSprite"
# export var color: = Color(1, 1, 1)

func _start() -> void:
	enemy.sprite.play("idle")
#	colored_sprite.play("idle")
