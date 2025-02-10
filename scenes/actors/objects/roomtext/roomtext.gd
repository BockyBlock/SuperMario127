extends GameObject

onready var sprite = $Sprite
onready var textes = $RichTextLabel
# onready var label = $CenterContainer


var slide_to_center_length := 1.25
var text := "This is a sign. Click on it in the editor to edit this text... scalawag."
var open_menu := false
var being_read := false
var character : Character

var normal_pos : Vector2
var transition_speed := 10.0
var reset_read_timer := 0.0

var check_timer := 3.0

var centered := false

export(Array, Texture) var palette_textures
export(Array, Texture) var palette_textures_2

func _set_properties():
	savable_properties = ["text"]
	editable_properties = ["text"]
	
func _set_property_values():
	set_property("text", text, true)

func _ready():
	if is_preview:
		z_index = 0
		sprite.z_index = 0
	
	if !visible and mode != 1:
		visible = true
	
	if mode != 1:
		textes.visible = true
		sprite.visible = false
		# label.call_deferred("update_sizing")
		textes.bbcode_text = "[center]" + text + "[/center]"

## compatibility w/ pop-up prefab
var bubble_text: String setget ,get_bubble_text
func get_bubble_text():
	return text
