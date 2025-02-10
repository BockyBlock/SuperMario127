extends EnemyState


onready var animation_player = $"%AnimationPlayer"
# onready var death_particles = $"%DeathParticles"
onready var timer = $"%Timer"


func _start() -> void:
	print("Taking damage")
	animation_player.play("die")
	enemy.sprite.hide()
	enemy.recolorable.hide()
	# death_particles.emitting = true
	
	timer.stop()
	timer.start(1)
	timer.connect("timeout", enemy, "queue_free")
