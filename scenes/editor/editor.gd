extends LevelDataLoader

var mode = 1

export var placement_mode := "Drag"
export var surface_snap := false
export var placeable_items : NodePath
export var placeable_items_button_container : NodePath
export var item_preview : NodePath
export var shared : NodePath
export var object_settings : NodePath
var selected_box : Node
var selected_object : Node

onready var placeable_items_node = get_node(placeable_items)
onready var placeable_items_button_container_node = get_node(placeable_items_button_container)
onready var item_preview_node = get_node(item_preview)
onready var shared_node = get_node(shared)
onready var object_settings_node = get_node(object_settings)

var lock_axis = "none"
var lock_pos = 0
var last_mouse_pos = Vector2(0, 0)

var left_held = false
var right_held = false

var hovered_object
var rotating = false

export var layer = 1

func get_shared_node():
	return shared_node

func switch_layers():
	if layer == 0:
		layer = 1
	elif layer == 1:
		layer = 2
	else:
		layer = 0

func _unhandled_input(event):
	if event.is_action_pressed("switch_placement_mode"):
		placement_mode = "Tile" if placement_mode == "Drag" else "Drag"
	elif event.is_action_pressed("toggle_surface_snap"):
		surface_snap = !surface_snap
	elif event.is_action_pressed("place"):
		left_held = true
	elif event.is_action_released("place"):
		left_held = false
	elif event.is_action_pressed("erase"):
		right_held = true
	elif event.is_action_released("erase"):
		right_held = false

func _ready():
	var data = CurrentLevelData.level_data
	load_in(data, data.areas[0])
	
func set_selected_box(selected_box: Node):
	item_preview_node.update_preview(selected_box.item)
	self.selected_box = selected_box
	for placeable_item_button in placeable_items_button_container_node.get_children():
		placeable_item_button.update_selection()

func switch_scenes():
	get_tree().change_scene("res://scenes/player/player.tscn")

func _process(delta):
	if get_viewport().get_mouse_position().y > 70:
		var mouse_pos = get_global_mouse_position()
		var mouse_screen_pos = get_viewport().get_mouse_position()
		if Input.is_action_pressed("lock_tile_axis") and (Input.is_action_pressed("place") or Input.is_action_pressed("erase")):
			if Input.is_action_just_pressed("place") or Input.is_action_just_pressed("erase"):
				if abs(mouse_pos.x) - abs(last_mouse_pos.x) > abs(mouse_pos.y) - abs(last_mouse_pos.y):
					lock_axis = "x"
					lock_pos = mouse_pos.x
				else:
					lock_axis = "y"
					lock_pos = mouse_pos.y
			if lock_axis == "x":
				mouse_pos.x = lock_pos
			elif lock_axis == "y":
				mouse_pos.y = lock_pos
		else:
			lock_axis = "none"
			lock_pos = 0
		
		var mouse_tile_pos = Vector2(floor(mouse_pos.x / 32), floor(mouse_pos.y / 32))
		var tile_index = tile_util.get_tile_index_from_position(mouse_tile_pos, level_area.settings.size)
		
		if selected_box and selected_box.item and selected_box.item.is_object:
			var objects = shared_node.get_objects_overlapping_position(mouse_pos)
			if objects.size() > 0 and placement_mode != "Tile" and !rotating:
				if hovered_object != objects[0]:
					if hovered_object != null:
						hovered_object.modulate = Color(1, 1, 1)
					hovered_object = objects[0]
					hovered_object.modulate = Color(0.65, 0.65, 1)
					item_preview_node.visible = false
			elif hovered_object != null and !rotating:
				hovered_object.modulate = Color(1, 1, 1)
				hovered_object = null
				item_preview_node.visible = true
		
		if hovered_object and Input.is_action_just_pressed("rotate"):
			rotating = true
		
		if hovered_object and rotating:
			hovered_object.rotation = -90 + hovered_object.position.angle_to_point(mouse_pos)
			if Input.is_action_pressed("8_pixel_lock"):
				hovered_object.rotation_degrees = stepify(hovered_object.rotation_degrees, 15)
				
		if hovered_object and left_held and Input.is_action_just_pressed("place"):
			if !rotating:
				object_settings_node.open_object(hovered_object)
			else:
				rotating = false
				hovered_object.set_property("rotation_degrees", fmod(hovered_object.rotation_degrees, 360), true)
		
		if left_held and selected_box and selected_box.item:
			var item = selected_box.item
			
			if !item.is_object:
				if item.on_place(mouse_tile_pos, level_data, level_area):
					if mouse_tile_pos.x > -1 and mouse_tile_pos.y > -1 and mouse_tile_pos.x < level_area.settings.size.x and mouse_tile_pos.y < level_area.settings.size.y:
						shared_node.set_tile(tile_index, layer, item.tileset_id, item.tile_id)
			elif hovered_object == null:
				var object_pos
				if placement_mode == "Tile":
					object_pos = (mouse_tile_pos * 32) + item.object_center
				elif Input.is_action_just_pressed("place"):
					object_pos = mouse_pos
					if Input.is_action_pressed("8_pixel_lock"):
						object_pos = Vector2(stepify(object_pos.x, 8), stepify(object_pos.y, 8))
					if surface_snap:
						var object_bottom = object_pos + Vector2(0, item.object_size.y)
						var space_state = get_world_2d().direct_space_state
						var result = space_state.intersect_ray(object_bottom, object_bottom + Vector2(0, 16))
						if result:
							object_pos = result.position - Vector2(0, item.object_size.y)
				if object_pos and !shared_node.is_object_at_position(object_pos) and item.on_place(object_pos, level_data, level_area):
					var object = LevelObject.new()
					object.type_id = item.object_id
					object.properties = []
					object.properties.append(object_pos)
					object.properties.append(Vector2(1, 1))
					object.properties.append(0)
					object.properties.append(true)
					object.properties.append(true)
					var object_node = shared_node.create_object(object, true)
		elif right_held:
			if selected_box:
				var item = selected_box.item
				if item.is_object:
					if placement_mode == "Tile":
						var object_pos = (mouse_tile_pos * 32) + item.object_center
						if item.on_erase(object_pos, level_data, level_area):
							shared_node.destroy_object_at_position(object_pos, true)
					elif Input.is_action_just_pressed("erase") and hovered_object and !rotating:
						if item.on_erase(mouse_pos, level_data, level_area):
							shared_node.destroy_object(hovered_object, true)
							hovered_object = null
							item_preview_node.visible = true
				else:
					if item.on_erase(mouse_tile_pos, level_data, level_area):
						if mouse_tile_pos.x > -1 and mouse_tile_pos.y > -1 and mouse_tile_pos.x < level_area.settings.size.x and mouse_tile_pos.y < level_area.settings.size.y:
							shared_node.set_tile(tile_index, layer, 0, 0)
		last_mouse_pos = mouse_pos