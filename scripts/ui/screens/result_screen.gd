extends BaseScreen
## Match result: winner, finishing places, play again or go home.

const PLACES := ["1st", "2nd", "3rd", "4th"]


func build() -> void:
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	var config: MatchConfig = AppState.match_config
	var ranking: Array[int] = AppState.last_ranking
	if config == null or ranking.is_empty():
		content.add_child(UIKit.title("Match over", 56, Palette.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
		_add_buttons(config != null)
		return

	var winner := config.player_at_seat(ranking[0])
	var hero := CenterContainer.new()
	var preview := PawnPreview.new(winner.seat)
	preview.custom_minimum_size = Vector2(220, 240)
	hero.add_child(preview)
	content.add_child(hero)
	content.add_child(UIKit.title("%s wins!" % winner.display_name, 60, winner.color().lightened(0.3), HORIZONTAL_ALIGNMENT_CENTER))
	var mode := ModeRegistry.get_mode(config.mode_id)
	content.add_child(UIKit.label(mode.title, 28, Palette.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER))

	var table := UIKit.card()
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 14)
	for i in ranking.size():
		var player := config.player_at_seat(ranking[i])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		var place := UIKit.title(PLACES[i], 30, Palette.ACCENT if i == 0 else Palette.TEXT_MUTED)
		place.custom_minimum_size = Vector2(80, 0)
		row.add_child(place)
		row.add_child(UIKit.color_dot(player.color(), 34))
		var name_label := UIKit.title(player.display_name, 30)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		rows.add_child(row)
	table.add_child(rows)
	content.add_child(table)
	content.add_child(UIKit.spacer())
	_add_buttons(true)
	_celebrate(preview)
	Sfx.play("yay", -2.0)
	var party := create_tween()
	party.tween_interval(0.6)
	party.tween_callback(Sfx.play.bind("party_horn", -2.0, 0.05))
	party.tween_interval(0.5)
	party.tween_callback(Sfx.play.bind("giggle", -3.0, 0.1))


func _add_buttons(can_replay: bool) -> void:
	if can_replay:
		var again := UIKit.button("Play Again")
		var mode := ModeRegistry.get_mode(AppState.match_config.mode_id)
		again.pressed.connect(SceneRouter.goto.bind(mode.game_screen if mode != null else "home"))
		content.add_child(again)
	var home := UIKit.button("Home", UIKit.ButtonKind.SECONDARY)
	home.pressed.connect(SceneRouter.goto.bind("home"))
	content.add_child(home)


func _celebrate(target: Control) -> void:
	target.pivot_offset = target.custom_minimum_size * 0.5
	var tween := create_tween().set_loops(3)
	tween.tween_property(target, "scale", Vector2(1.12, 1.12), 0.22).set_trans(Tween.TRANS_SINE)
	tween.tween_property(target, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_SINE)


func handle_back() -> void:
	SceneRouter.goto("home")
