class_name RenderSprite
extends Sprite2D


@onready var labels_container := $Labels

var dynamic_font: Font = null  # preload("res://custom_font.otf")
var radius: int = 300
var font_size: int = 30
var configured_slices: Array[IndividualSlice] = []
var wobble: bool = true
var arcs: PackedVector2Array


func _on_scene_ready() -> void:
	if self.configured_slices.is_empty():
		load_defaults()


func load_defaults() -> void:
	var new_settings := Settings.new()
	new_settings.font_size = 30
	new_settings.radius = 200
	new_settings.wobble = false
	var slice_setting := IndividualSlice.new()
	slice_setting.message = "Blue"
	slice_setting.color = Color.BLUE
	slice_setting.weight = 1
	new_settings.slices.push_back(slice_setting)
	slice_setting = IndividualSlice.new()
	slice_setting.message = "Red"
	slice_setting.color = Color.RED
	slice_setting.weight = 1
	new_settings.slices.push_back(slice_setting)
	slice_setting = IndividualSlice.new()
	slice_setting.message = "Green"
	slice_setting.color = Color.GREEN
	slice_setting.weight = 1
	new_settings.slices.push_back(slice_setting)
	update(new_settings)


func update(settings: Settings) -> void:
	self.configured_slices.clear()
	self.radius = settings.radius
	self.font_size = settings.font_size
	self.wobble = settings.wobble
	for slice in settings.slices:
		var slice_setting = IndividualSlice.new()
		slice_setting.message = slice.message
		slice_setting.color = slice.color
		slice_setting.weight = slice.weight
		self.configured_slices.push_back(slice_setting)
	queue_redraw()


class SliceInfo:
	var starting_angle: float = 0.0
	var angle_size: float = 0.0


func newSliceInfo(starting_angle_, angle_size_) -> SliceInfo:
	var obj = SliceInfo.new()
	obj.starting_angle = starting_angle_
	obj.angle_size = angle_size_
	return obj


func calculate_slices(slice_values: PackedInt32Array) -> Array[SliceInfo]:
	var slices_: Array[SliceInfo]
	var total_: = 0
	for i in slice_values:
		total_ += i
	var point_value_: = 2 * PI / total_
	var angle_progress_ = 0.0
	for i in slice_values:
		var angle_size_ := point_value_ * i
		var info_ := newSliceInfo(angle_progress_, angle_size_)
		slices_.append(info_)
		angle_progress_ += angle_size_
	return slices_


func reset_rotation() -> void:
	global_rotation = 0.0


func _draw() -> void:
	centered = true
	var slice_count_: int = self.configured_slices.size()
	if slice_count_ <= 0:
		return
	var slice_weights_: PackedInt32Array
	for i in slice_count_:
		slice_weights_.append(self.configured_slices[i].weight)
	var slice_infos := calculate_slices(slice_weights_)

	self.arcs = []
	var center := Vector2.ZERO
	var angle_position_ := 0.0
	var angle_idx_ := -1
	for slice_info in slice_infos:
		angle_idx_ += 1
		var start_angle_ := angle_position_
		var end_angle_ := start_angle_ + slice_info.angle_size
		angle_position_ += slice_info.angle_size
		var color_ :=  slice_color(angle_idx_)
		if angle_idx_ == slice_count_ - 1 and slice_color(0) == color_:
			color_ = slice_color(1)
		draw_circle_slice(center, start_angle_, end_angle_, color_)
		draw_rotated_label(center, (start_angle_ + end_angle_) / 2.0,
				self.configured_slices[angle_idx_].message,
				Color.BLACK, Color.HOT_PINK)

	# Subtracting ONE causes the slight wobble effect
	var wobble_it_ := Vector2.ZERO
	if self.wobble:
		wobble_it_ = Vector2.ONE
	# Draw border
	draw_circle(center - wobble_it_, self.radius, Color.BLACK, false, 2.0, true)


func slice_color(idx: int) -> Color:
	return self.configured_slices[idx % self.configured_slices.size()].color


func draw_circle_slice(center: Vector2, angle_from_rad: float, angle_to_rad: float, color: Color):
	var nb_points_ := 32  # Number of points to approximate the arc
	var points_arc_ := PackedVector2Array()

	# Add the center point first
	points_arc_.append(center)

	# Calculate the angle increment for each point
	var angle_step_: float = absf(angle_to_rad - angle_from_rad) / nb_points_
	var start_pt_ := Vector2.INF
	var end_pt_ := Vector2.INF

	# Generate points along the arc
	for i in range(nb_points_ + 1):
		var current_angle_ := angle_from_rad + i * angle_step_
		var rotator_ := Vector2(cos(current_angle_), sin(current_angle_))
		var pt_ = center + rotator_ * self.radius
		points_arc_.append(pt_)
		if i == 0:
			start_pt_ = pt_
		else:
			end_pt_ = pt_
	if self.arcs.is_empty():
		self.arcs.append(start_pt_)
	self.arcs.append(end_pt_)
	draw_colored_polygon(points_arc_, color)
	# Draw the border
	var points_border_ := PackedVector2Array()
	points_border_.append(center)
	points_border_.append(start_pt_)
	points_border_.append(center)
	points_border_.append(end_pt_)
	draw_multiline(points_border_, Color.BLACK, 2.0, true)


func draw_rotated_label(center_: Vector2, angle_radians_: float, message_: String,
		color_: Color, shadow_color_: Color):
	var new_label_ := Label.new()
	new_label_.text = message_
	new_label_.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if self.dynamic_font:
		new_label_.add_theme_font_override("font", self.dynamic_font)
	new_label_.add_theme_font_size_override('font_size', self.font_size)
	new_label_.add_theme_color_override('font_color', color_)
	new_label_.add_theme_color_override('font_shadow_color', shadow_color_)
	#new_label.add_theme_constant_override('shadow_offset_x', int(vertical_adjustment.x))
	#new_label.add_theme_constant_override('shadow_offset_y', int(vertical_adjustment.y))
	new_label_.add_theme_constant_override('shadow_outline_size', 4)

	var text_area_: Vector2 = new_label_.get_theme_font("font").get_string_size(
		new_label_.text, HORIZONTAL_ALIGNMENT_RIGHT, -1, new_label_.get_theme_font_size("font_size"))
	
	var perpendicular_angle_ := angle_radians_ + PI/2.0
	var vertical_adjustment_: Vector2 = Vector2.from_angle(perpendicular_angle_) * (text_area_.y/2.0)
	var x_slack_ := self.radius - text_area_.x
	if x_slack_ < 30.0:
		# Insufficient space to display the label, abort
		return
	var x_adj_ := 30.0
	var center_tweak_: Vector2 = Vector2.from_angle(angle_radians_) * x_adj_
	#var center_tweak := center_offset * Vector2(cos(angle_radians), sin(angle_radians))
	var adjusted_center_ := center_ + center_tweak_ - vertical_adjustment_

	new_label_.custom_minimum_size = Vector2(self.radius - x_adj_, 0.0)
	new_label_.position = adjusted_center_
	new_label_.rotation = angle_radians_
	labels_container.add_child(new_label_)


func get_arcs() -> PackedVector2Array:
	return self.arcs


func to_settings() -> Settings:
	var settings = Settings.new()
	settings.radius = self.radius
	settings.font_size = self.font_size
	settings.wobble = self.wobble
	settings.slices = self.configured_slices.duplicate()
	return settings
