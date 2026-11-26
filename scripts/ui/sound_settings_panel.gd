class_name SoundSettingsPanel
extends VBoxContainer
## Sound on/off and volume sliders (all sounds + one per group).
## Used on the Settings screen and in the pause menu. Changes apply and save at once.

const SfxScript := preload("res://scripts/autoload/sfx.gd")

var _sliders: Dictionary = {}
var _percent_labels: Dictionary = {}
var _toggle: Button

static var _grabber: Texture2D


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	_toggle = UIKit.button("", UIKit.ButtonKind.SECONDARY, 80)
	_toggle.pressed.connect(func() -> void:
		Sfx.set_enabled(not Sfx.enabled)
		_refresh()
	)
	add_child(_toggle)
	_add_row("master", "All sounds")
	for group in SfxScript.GROUPS:
		_add_row(group, SfxScript.GROUPS[group][1])
	_refresh()


func slider(key: String) -> HSlider:
	return _sliders.get(key)


func _add_row(key: String, title: String) -> void:
	var header := HBoxContainer.new()
	var name_label := UIKit.label(title, 24, Palette.TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)
	var percent := UIKit.label("", 22, Palette.TEXT_MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	header.add_child(percent)
	add_child(header)

	var s := HSlider.new()
	s.min_value = 0
	s.max_value = 100
	s.step = 5
	s.custom_minimum_size = Vector2(0, 44)
	s.focus_mode = Control.FOCUS_NONE
	s.value = roundf(Sfx.get_volume(key) * 100.0)
	_style_slider(s)
	s.value_changed.connect(func(v: float) -> void:
		Sfx.set_volume(key, v / 100.0)
		_refresh()
	)
	# A short sample so players hear the new level.
	s.drag_ended.connect(func(_changed: bool) -> void: Sfx.play(_sample_for(key)))
	add_child(s)
	_sliders[key] = s
	_percent_labels[key] = percent


func _sample_for(key: String) -> String:
	match key:
		"moves":
			return "dice_land"
		"battle":
			return "gunshot"
		"jingles":
			return "extra"
	return "click"


func _refresh() -> void:
	_toggle.text = "Sound: On" if Sfx.enabled else "Sound: Off"
	for key in _sliders:
		(_percent_labels[key] as Label).text = "%d%%" % int(round(Sfx.get_volume(key) * 100.0))
		(_sliders[key] as HSlider).editable = Sfx.enabled


func _style_slider(s: HSlider) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color(1, 1, 1, 0.15)
	track.set_corner_radius_all(6)
	track.content_margin_top = 6
	track.content_margin_bottom = 6
	var filled := StyleBoxFlat.new()
	filled.bg_color = Palette.ACCENT
	filled.set_corner_radius_all(6)
	filled.content_margin_top = 6
	filled.content_margin_bottom = 6
	s.add_theme_stylebox_override("slider", track)
	s.add_theme_stylebox_override("grabber_area", filled)
	s.add_theme_stylebox_override("grabber_area_highlight", filled)
	var knob := _knob_texture()
	s.add_theme_icon_override("grabber", knob)
	s.add_theme_icon_override("grabber_highlight", knob)


## A round white knob, drawn once.
static func _knob_texture() -> Texture2D:
	if _grabber == null:
		var knob_size := 40
		var image := Image.create(knob_size, knob_size, false, Image.FORMAT_RGBA8)
		var centre := Vector2(knob_size, knob_size) * 0.5
		for y in knob_size:
			for x in knob_size:
				var d := Vector2(x + 0.5, y + 0.5).distance_to(centre)
				var alpha := clampf(knob_size * 0.5 - d, 0.0, 1.0)
				var color := Color.WHITE if d < knob_size * 0.5 - 4.0 else Palette.ACCENT
				image.set_pixel(x, y, Color(color, alpha))
		_grabber = ImageTexture.create_from_image(image)
	return _grabber
