extends Node2D

@export var settings: Settings
@export var max_rotation_speed: int = 20  # Degress per second
@export var min_time: float = 4.4
@export var max_time: float = 6.0
@export var rotation_curve: Curve
@export var auto_wheel: bool = true

signal wheel_stopped

@onready var pin_scene: Resource = preload("res://pin.tscn")
@onready var render_sprite = $RenderSprite
@onready var pins_container = $RenderSprite/Pins
@onready var label_container = $RenderSprite/Labels
@onready var flipper = get_node("/root/Main/Flipper")

var prng = RandomNumberGenerator.new()
var rotation_rad: float = 0
var spin_time: float = 0.0
var current_time: float = 0.0
var mouse_moving: Vector2 = Vector2.INF
var exit_delay: float = 1e10
var trigger_setup_pins: bool = true
var settings_ui = null
var next_spin_settings: Settings = null
var old_radius: float = 0.0
var do_reset_settings: bool = false

const SAVE_PATH: String = "user://wheel.tres"


func _ready() -> void:
	get_tree().get_root().set_transparent_background(true)
	load_settings()
	resize_window()
	if auto_wheel:
		$Timer.start()


func remove_labels() -> void:
	for label in label_container.get_children():
		label.queue_free()


func spin() -> void:
	if do_reset_settings:
		do_reset_settings = false
		reset_settings()
	if trigger_setup_pins:
		setup_pins()
	spin_time = prng.randf_range(min_time, max_time)
	current_time = 0.0


func load_settings() -> void:
	if not ResourceLoader.exists(SAVE_PATH, "Settings"):
		render_sprite.load_default_slices()
		save_settings()
	print("Settings loaded from ", SAVE_PATH)
	settings = ResourceLoader.load(SAVE_PATH, "Settings") as Settings
	reload_settings()


func fix_settings() -> bool:
	var fs := self.settings.font_size
	self.settings.font_size = mini(300, maxi(6, fs))
	var rad := self.settings.radius
	var window_size := DisplayServer.window_get_size()
	var max_rad: int = (min(window_size.x, window_size.y) - 60) / 2.0
	self.settings.radius = mini(max_rad, maxi(100, rad))
	return self.settings.font_size != fs || self.settings.radius != rad


func resize_window() -> void:
	#var wheel_size := int(self.old_radius + self.old_radius + 10)
	#var new_bounds := Vector2i(wheel_size + 10, wheel_size + 60)
	#DisplayServer.window_set_size(new_bounds)
	self.flipper.position = Vector2(self.old_radius + 5, 50)
	position = Vector2(self.old_radius + 5, self.old_radius + 60)


func reload_settings(swap_in_new: bool = false) -> void:
	var save = false
	if swap_in_new:
		if next_spin_settings:
			settings = next_spin_settings
			next_spin_settings = null
			# save_settings scrapes the current wheel state so it must be
			# updated with the new settings first
			save = true
	if fix_settings():
		save = true
	render_sprite.rotate(0.0)
	render_sprite.update(settings)
	if settings.radius != old_radius:
		old_radius = settings.radius
		resize_window()
	trigger_setup_pins = true
	remove_pins()
	remove_labels()
	if save:
		save_settings()


func save_settings() -> void:
	settings = render_sprite.to_settings()
	ResourceSaver.save(settings, SAVE_PATH)
	print("New settings written to ", SAVE_PATH)


func _on_settings_updated(incoming_settings: Settings) -> void:
	next_spin_settings = incoming_settings
	if spin_time == 0.0:
		reload_settings(true)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_action_pressed("right_click"):
			if mouse_moving == Vector2.INF:
				mouse_moving = get_global_mouse_position()
		else:
			mouse_moving = Vector2.INF
		if event.is_action_pressed("left_click"):
			if exit_delay > 1e5:
				exit_delay = 1.0  # 1 second click to exit
		else:
			if not is_spinning() and exit_delay < 1e5 and !auto_wheel:
				spin()
			exit_delay = 1e10
	elif event is InputEventKey:
		if event.is_action_pressed("open_config"): 
			if settings_ui == null:
				open_settings_ui()


func _process(delta: float) -> void:
	if exit_delay < 1e5:
		exit_delay -= delta
		if exit_delay < 0.001:
			get_tree().quit()
	elif mouse_moving != Vector2.INF:
		var dvec := get_global_mouse_position() - mouse_moving
		var fpos: Vector2 = get_window().position
		get_window().position = fpos.lerp(fpos + dvec, 50*delta)
		mouse_moving = get_global_mouse_position()


func _physics_process(delta):
	if !is_spinning() or current_time >= spin_time:
		return
	current_time += delta
	var progress = current_time / spin_time
	var progress_sample = rotation_curve.sample(progress)
	var cur_rotation = global_rotation
	var rotation_ = cur_rotation + deg_to_rad(max_rotation_speed) * progress_sample
	render_sprite.rotate(rotation_)
	if current_time >= spin_time:
		current_time = 0.0
		spin_time = 0.0
		wheel_stopped.emit()
		if next_spin_settings:
			call_deferred("reload_settings", true)


func setup_pins():
	var arcs: PackedVector2Array = render_sprite.get_arcs()
	if arcs.size() <= 0:
		return
	trigger_setup_pins = false
	remove_pins()
	# pin_scene
	for arc_pt in arcs:
		var real_pin = pin_scene.instantiate()
		real_pin.position = arc_pt
		pins_container.add_child(real_pin)


func remove_pins():
	for child in pins_container.get_children():
		child.queue_free()


func open_settings_ui() -> void:
	var settings_ui_scn = load("res://settings_ui.tscn")
	settings_ui = settings_ui_scn.instantiate()
	get_tree().root.add_child(settings_ui)
	settings_ui.settings_updated.connect(_on_settings_updated)
	settings_ui.reset_settings.connect(_on_settings_reset_request)
	settings_ui.load_settings(settings)


func is_spinning() -> bool:
	return spin_time > 0.001


func _on_wheel_stopped() -> void:
	if do_reset_settings:
		do_reset_settings = false
		reset_settings()
	if auto_wheel:
		$Timer.start()


func _on_timer_timeout() -> void:
	spin()


func _on_settings_reset_request() -> void:
	if is_spinning():
		do_reset_settings = true
	else:
		reset_settings()


func reset_settings() -> void:
	print('reset settings')
	render_sprite.load_defaults()
	save_settings()
	remove_pins()
	load_settings()
