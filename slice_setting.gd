class_name SliceSetting
extends MarginContainer

@onready var color_box = $ColorBox
@onready var weight_tbx = $ColorBox/MarginContainer/TextBoxContainer/WeightEdit
@onready var text_tbx = $ColorBox/MarginContainer/TextBoxContainer/TextEdit
@onready var color_selector = preload("res://color_selector.tscn")

signal color_selector_request(current_color: Color, callback: Callable)
signal delete_request(node: SliceSetting)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup_stylebox()


func setup_stylebox() -> void:
	var stylebox = color_box.get_theme_stylebox('panel').duplicate()
	color_box.add_theme_stylebox_override('panel', stylebox)


func get_text() -> String:
	return text_tbx.text


func set_text(text: String):
	text_tbx.text = text


func get_color() -> Color:
	var stylebox: StyleBox = color_box.get_theme_stylebox('panel')
	if stylebox is StyleBoxFlat:
		return stylebox.bg_color
	else:
		print("The panel's stylebox is not a StyleBoxFlat or does not have a background color property.")
		return Color.WHITE


func set_color(color: Color):
	color.a8 = 255
	var stylebox = color_box.get_theme_stylebox('panel')
	if stylebox is StyleBoxFlat:
		stylebox.bg_color = color
	else:
		print("The panel's stylebox is not a StyleBoxFlat, blasting.")
		var style = load("res://slice_setting.tres")
		color_box.add_theme_stylebox_override("panel", style)


func get_weight() -> int:
	var weight_txt = str(weight_tbx.text)
	if weight_txt.is_valid_int():
		var weight = int(weight_txt)
		if weight > 0 && weight <= 1000:
			return weight
	return 1


func set_weight(weight: int) -> void:
	weight_tbx.text = str(weight)


func open_color_selector():
	emit_signal("color_selector_request", get_color(), set_color)


func _on_texture_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				open_color_selector()


func _on_delete_button_pressed() -> void:
	emit_signal("delete_request", self)
