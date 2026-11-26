extends BaseScreen
## Game history: finished matches on this device, newest first.

const PLACES := ["1st", "2nd", "3rd", "4th"]

var list: VBoxContainer


func build() -> void:
	add_header("Game History")
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	scroll.add_child(list)
	content.add_child(scroll)

	if AppState.history.is_empty():
		list.add_child(UIKit.label("No games yet. Finished matches will appear here.", 26, Palette.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER, true))
		return
	for entry in AppState.history:
		list.add_child(_entry_card(entry))


func entry_count() -> int:
	return list.get_child_count() if not AppState.history.is_empty() else 0


func _entry_card(entry: Dictionary) -> Control:
	var card := UIKit.card(Palette.PANEL, 22, 16)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var mode := ModeRegistry.get_mode(str(entry.get("mode_id", "")))
	var title := mode.title if mode != null else "Match"
	if mode != null and mode.has_board_choice:
		title += "  -  " + SnlBoards.get_board(str(entry.get("board_id", ""))).title
	var top := HBoxContainer.new()
	var mode_label := UIKit.title(title, 26)
	mode_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(mode_label)
	top.add_child(UIKit.label(_date(int(entry.get("time", 0))), 20, Palette.TEXT_MUTED, HORIZONTAL_ALIGNMENT_RIGHT))
	box.add_child(top)

	var names := {}
	for p in entry.get("players", []):
		names[int(p.get("seat", 0))] = str(p.get("name", ""))
	var ranking: Array = entry.get("ranking", [])
	for i in ranking.size():
		var seat := int(ranking[i])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var place := UIKit.label(PLACES[mini(i, 3)], 22, Palette.ACCENT if i == 0 else Palette.TEXT_MUTED)
		place.custom_minimum_size = Vector2(56, 0)
		row.add_child(place)
		row.add_child(UIKit.color_dot(Palette.seat_color(seat), 24))
		row.add_child(UIKit.label(names.get(seat, Palette.seat_name(seat)), 22, Palette.TEXT))
		box.add_child(row)
	card.add_child(box)
	return card


func _date(unix_time: int) -> String:
	if unix_time <= 0:
		return ""
	var d := Time.get_datetime_dict_from_unix_time(unix_time)
	return "%02d/%02d/%d %02d:%02d" % [d["day"], d["month"], d["year"], d["hour"], d["minute"]]


func handle_back() -> void:
	SceneRouter.goto("profile")
