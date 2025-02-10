extends EnemyBase

export var is_stationary: bool = false
export var rainbow: bool = false
export var color: = Color(1, 1, 1)


func _enter_tree():
	cur_state = "IdleState" if is_stationary else "PatrolState"
	

func set_default_state():
	set_state_by_name("IdleState" if is_stationary else "PatrolState")

func _process(_delta)->void :
	recolorable.frame = sprite.frame
	recolorable.animation = sprite.animation
	recolorable.flip_h = sprite.flip_h
	
	recolorable.position = sprite.position
	recolorable.reset_physics_interpolation()
	recolorable.scale = sprite.scale
	recolorable.rotation = sprite.rotation
	
	recolorable.position = Vector2(0,0)
	
	recolorable.visible = sprite.visible
	if rainbow:
		color.h = float(wrapi(OS.get_ticks_msec(), 0, 1000)) / 1000
		if enabled:
			self.collision_layer = 536870916
	recolorable.self_modulate = color
	
