extends CanvasLayer
## Switches between screens with a short fade, and forwards the Android back
## button (and Escape on desktop) to the current screen's handle_back().

const SCREENS := {
	"splash": "res://scenes/screens/splash.tscn",
	"welcome": "res://scenes/screens/welcome.tscn",
	"home": "res://scenes/screens/home.tscn",
	"player_select": "res://scenes/screens/player_select.tscn",
	"lobby": "res://scenes/screens/lobby.tscn",
	"game": "res://scenes/screens/game.tscn",
}
const FADE_TIME := 0.16

var _fade: ColorRect
var _busy := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade = ColorRect.new()
	_fade.color = Palette.BG_BOTTOM
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	add_child(_fade)


func goto(screen_id: String) -> void:
	if _busy:
		return
	if not SCREENS.has(screen_id):
		push_error("Unknown screen: %s" % screen_id)
		return
	_busy = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", 1.0, FADE_TIME)
	await tween.finished
	var err := get_tree().change_scene_to_file(SCREENS[screen_id])
	if err != OK:
		push_error("Could not open screen %s (error %d)." % [screen_id, err])
	tween = create_tween()
	tween.tween_property(_fade, "modulate:a", 0.0, FADE_TIME)
	await tween.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_send_back()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_send_back()
		get_viewport().set_input_as_handled()


func _send_back() -> void:
	if _busy:
		return
	var screen := get_tree().current_scene
	if screen != null and screen.has_method("handle_back"):
		screen.call("handle_back")
