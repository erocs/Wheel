class_name ColorSelector
extends PanelContainer

@onready var color_picker = $MarginContainer/VBoxContainer/ColorPicker

signal color_selected(color: Color)


func set_color(color: Color) -> void:
	color_picker.color = color


func _on_apply_button_pressed() -> void:
	emit_signal("color_selected", color_picker.color)
	queue_free()
