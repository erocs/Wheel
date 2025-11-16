class_name SettingsUi
extends ScrollContainer

@onready var slice_container = $Border/HBoxContainer/LayoutContainer/SliceContainer
@onready var top_hbox = $Border/HBoxContainer
@onready var hbox_child = $Border/HBoxContainer/LayoutContainer
@onready var wobble_ckbx = $Border/HBoxContainer/LayoutContainer/WobbleCheck
@onready var radius_tbx = $Border/HBoxContainer/LayoutContainer/RadiusHBox/RadiusTBox
@onready var font_size_tbx = $Border/HBoxContainer/LayoutContainer/FontSizeHBox/FontSizeTBox

signal settings_updated(settings: Settings)
signal reset_settings

var slice_setting_scn = preload("res://slice_setting.tscn")
var color_selector_scn = preload("res://color_selector.tscn")


func load_settings(settings: Settings) -> void:
	clear_slices()
	radius_tbx.text = str(settings.radius)
	font_size_tbx.text = str(settings.font_size)
	wobble_ckbx.button_pressed = settings.wobble
	for slice in settings.slices:
		add_slice(slice)


func generate_random_rgb_color() -> Color:
	return Color(randf(), randf(), randf())


func generate_random_hsv_color() -> Color:
	# Generate random hue, saturation, and value within desired ranges
	var hue = randf() # 0.0 to 1.0 for full hue range
	var saturation = randf_range(0.5, 1.0) # Example: more saturated colors
	# var value = randf_range(0.8, 1.0) # Example: brighter colors
	return Color.from_hsv(hue, saturation, 1.0)


func clear_slices() -> void:
	for child in slice_container.get_children():
		slice_container.remove_child(child)


func add_random_slice() -> void:
	var slice_setting: SliceSetting = slice_setting_scn.instantiate()
	slice_container.add_child(slice_setting)
	slice_setting.color_selector_request.connect(_on_open_color_selector)
	slice_setting.delete_request.connect(_on_delete_color)
	#slice_setting.set_color(generate_random_rgb_color())
	slice_setting.set_color(generate_random_hsv_color())


func add_slice(slice: IndividualSlice) -> void:
	var slice_setting: SliceSetting = slice_setting_scn.instantiate()
	slice_container.add_child(slice_setting)
	slice_setting.color_selector_request.connect(_on_open_color_selector)
	slice_setting.delete_request.connect(_on_delete_color)
	slice_setting.set_text(slice.message)
	slice_setting.set_color(slice.color)
	slice_setting.set_weight(slice.weight)


func clear_color_selector() -> void:
	for child in top_hbox.get_children():
		top_hbox.remove_child(child)
	top_hbox.add_child(hbox_child)


func slices_to_settings() -> Array[IndividualSlice]:
	var slice_array: Array[IndividualSlice] = []
	for slice in slice_container.get_children():
		var new_slice = IndividualSlice.new()
		new_slice.message = slice.get_text()
		new_slice.color = slice.get_color()
		new_slice.weight = slice.get_weight()
		slice_array.push_back(new_slice)
	return slice_array


func _on_open_color_selector(current_color: Color, callback: Callable):
	if top_hbox.get_child_count() >= 2:
		clear_color_selector()
	var color_selector = color_selector_scn.instantiate()
	top_hbox.add_child(color_selector)
	color_selector.set_color(current_color)
	color_selector.color_selected.connect(_on_color_selected.bind(callback))


func _on_color_selected(color: Color, callback: Callable):
	callback.call(color)


func _on_delete_color(node: SliceSetting) -> void:
	if slice_container.get_child_count() > 1:
		node.queue_free()


func _on_add_wedge_pressed() -> void:
	add_random_slice()


func _on_apply_pressed() -> void:
	# Forward on new settings to the wheel. It will close this window.
	var settings = Settings.new()
	settings.radius = int(radius_tbx.text)
	settings.font_size = int(font_size_tbx.text)
	settings.wobble = wobble_ckbx.button_pressed
	settings.slices = slices_to_settings()
	emit_signal("settings_updated", settings)
	queue_free()


func _on_cancel_pressed() -> void:
	queue_free()


func _on_reset_pressed() -> void:
	reset_settings.emit()
	queue_free()
