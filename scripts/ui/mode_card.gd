class_name ModeCard
extends Button
## Large tappable card for choosing a game mode on the home screen.

var mode: GameMode


func _init(p_mode: GameMode) -> void:
	mode = p_mode
	custom_minimum_size = Vector2(0, 220)
	focus_mode = Control.FOCUS_NONE
	UIKit.style_button(self, mode.accent.darkened(0.35), Palette.TEXT, 2, 32)


func _ready() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	margin.add_child(row)
	row.add_child(ModeArt.new(mode.id))

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.add_theme_constant_override("separation", 6)
	row.add_child(texts)
	texts.add_child(UIKit.title(mode.title, 40))
	texts.add_child(UIKit.label(mode.tagline, 26, Palette.TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	texts.add_child(UIKit.title("PLAY  >", 24, Palette.ACCENT))

	UIKit.ignore_mouse_recursive(self)
	UIKit.add_press_feedback(self)
