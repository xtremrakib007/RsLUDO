extends BaseScreen
## How to play: Classic Ludo and Snakes & Ladders.

const CLASSIC := [
	["Goal", "Be the first to bring all four of your pawns from your base, around the board and into the centre."],
	["Starting", "Roll a 6 to bring a pawn out onto your coloured start square."],
	["Moving", "Tap the dice, then tap a glowing pawn to move it that many squares clockwise. If only one move is possible it happens automatically."],
	["Extra rolls", "Rolling a 6, capturing a pawn, or bringing a pawn home gives you another roll. Three 6s in a row ends your turn."],
	["Capturing", "Land exactly on an opponent's pawn to knock it back to its base."],
	["Safe squares", "Start squares and star squares are safe: pawns there cannot be captured."],
	["Going home", "After a full lap, pawns turn into their own coloured column. You need the exact number to reach the centre."],
]
const SNAKES := [
	["Goal", "Be the first to reach square 100."],
	["Moving", "Tap the dice and your character walks that many squares. Everyone starts straight away."],
	["Ladders", "Stop at the bottom of a ladder and climb straight to the top."],
	["Snakes", "Stop on a snake's head and it swallows you: you come out at its tail. Walking past a snake is safe."],
	["Extra rolls", "A 6 gives you another roll. Three 6s in a row ends your turn."],
	["Finishing", "You need the exact number to land on 100. If your roll is too big you stay where you are."],
	["Boards", "Choose from five boards with different snakes and ladders before the match."],
]


func build() -> void:
	add_header("Rules")
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 16)
	scroll.add_child(box)
	content.add_child(scroll)
	_add_section(box, ClassicMode.ID, CLASSIC)
	_add_section(box, SnakesLaddersMode.ID, SNAKES)


func _add_section(box: VBoxContainer, mode_id: String, items: Array) -> void:
	var mode := ModeRegistry.get_mode(mode_id)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	var art := ModeArt.new(mode_id)
	art.custom_minimum_size = Vector2(90, 90)
	head.add_child(art)
	var heading := UIKit.title(mode.title, 38)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(heading)
	box.add_child(head)
	var card := UIKit.card()
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 12)
	for item in items:
		list.add_child(UIKit.title(item[0], 26, Palette.ACCENT))
		list.add_child(UIKit.label(item[1], 24, Palette.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
	card.add_child(list)
	box.add_child(card)


func handle_back() -> void:
	SceneRouter.goto("home")
