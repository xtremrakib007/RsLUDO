extends BaseScreen
## Settings: sound on/off and volume levels.

var panel: SoundSettingsPanel


func build() -> void:
	add_header("Settings")
	content.add_child(UIKit.section_label("Sound"))
	var card := UIKit.card()
	panel = SoundSettingsPanel.new()
	card.add_child(panel)
	content.add_child(card)
	content.add_child(UIKit.label("Changes are saved on this device.", 22, Palette.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER))


func handle_back() -> void:
	SceneRouter.goto("home")
