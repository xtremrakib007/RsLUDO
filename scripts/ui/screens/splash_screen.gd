extends BaseScreen
## Splash: logo with a rolling dice, then the welcome screen (first launch)
## or the home screen (guest profile already exists).

var _dice: DiceFace


func build() -> void:
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	var holder := CenterContainer.new()
	_dice = DiceFace.new()
	_dice.custom_minimum_size = Vector2(170, 170)
	holder.add_child(_dice)
	content.add_child(holder)
	content.add_child(UIKit.title("RS Ludo", 80, Palette.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	content.add_child(UIKit.label("Roll. Race. Have fun together.", 30, Palette.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	_play_intro()


func _play_intro() -> void:
	content.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(content, "modulate:a", 1.0, 0.4)
	tween.parallel().tween_method(_spin_dice, 0.0, 1.0, 1.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.5)
	tween.tween_callback(_finish)


func _spin_dice(t: float) -> void:
	_dice.rotation = (1.0 - t) * TAU * 1.5
	_dice.value = 1 + int(t * 17.0) % 6


func _finish() -> void:
	SceneRouter.goto("home" if AppState.has_profile() else "welcome")
