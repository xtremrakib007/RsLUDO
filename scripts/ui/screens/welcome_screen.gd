extends BaseScreen
## First-launch welcome with the guest play option. Accounts come with online play.


func build() -> void:
	content.alignment = BoxContainer.ALIGNMENT_CENTER

	var pawns := HBoxContainer.new()
	pawns.alignment = BoxContainer.ALIGNMENT_CENTER
	pawns.add_theme_constant_override("separation", 8)
	for seat in BoardLayout.SEAT_COUNT:
		var preview := PawnPreview.new(seat)
		preview.custom_minimum_size = Vector2(120, 140)
		pawns.add_child(preview)
	content.add_child(pawns)

	content.add_child(UIKit.title("Welcome to Ludo Social", 52, Palette.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	content.add_child(UIKit.label("Play Ludo and Snake Ludo with family and friends on one device.", 30, Palette.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER, true))
	content.add_child(UIKit.spacer(false))

	var guest := UIKit.button("Play as Guest")
	guest.pressed.connect(_on_guest)
	content.add_child(guest)

	var sign_in := UIKit.button("Sign In", UIKit.ButtonKind.SECONDARY)
	sign_in.pressed.connect(show_toast.bind("Accounts arrive with online play in a future update."))
	content.add_child(sign_in)

	content.add_child(UIKit.label("As a guest, your name and progress stay on this device.", 24, Palette.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER, true))


func _on_guest() -> void:
	AppState.create_guest_profile()
	SceneRouter.goto("home")


func handle_back() -> void:
	get_tree().quit()
