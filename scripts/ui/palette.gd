class_name Palette
extends RefCounted
## All colours in one place so the look can be re-skinned later.

const BG_TOP := Color("1f3184")
const BG_BOTTOM := Color("0d1333")
const PANEL := Color(1, 1, 1, 0.08)
const PANEL_STRONG := Color(1, 1, 1, 0.13)
const PANEL_BORDER := Color(1, 1, 1, 0.16)
const OVERLAY := Color(0.02, 0.03, 0.08, 0.78)
const TEXT := Color("f5f7ff")
const TEXT_MUTED := Color("aab3d9")
const TEXT_DARK := Color("1d2240")
const ACCENT := Color("ffc531")
const CLASSIC_ACCENT := Color("4f6bff")
const SNAKE_ACCENT := Color("27a85a")
const SNAKE_BODY := Color("49c26b")
const SNAKE_BELLY := Color("c9f08a")

const BOARD_BG := Color("fdfaf2")
const BOARD_FRAME := Color("2a2f55")
const BOARD_LINE := Color("cfc8b3")
const STAR := Color("b9b19b")

const SEAT_COLORS := [Color("e8413c"), Color("2fb457"), Color("f6c026"), Color("2f7fe0")]
const SEAT_NAMES := ["Red", "Green", "Yellow", "Blue"]
## Snake colours on the Snake Ludo board (cartoon, friendly).
const SNAKE_COLORS := [Color("3dbb6b"), Color("8e5bd6"), Color("f08a24"), Color("1aa3a3")]
## Placeholder character skin tones, one per seat, for visual variety.
const SKIN_TONES := [Color("f2c7a5"), Color("8d5a3b"), Color("e0ac69"), Color("c68642")]


static func seat_color(seat: int) -> Color:
	return SEAT_COLORS[seat]


static func seat_name(seat: int) -> String:
	return SEAT_NAMES[seat]


static func snake_color(index: int) -> Color:
	return SNAKE_COLORS[posmod(index, SNAKE_COLORS.size())]


static func skin_tone(seat: int) -> Color:
	return SKIN_TONES[seat]


## Seat colour faded towards grey, for seats nobody plays in.
static func inactive_seat_color(seat: int) -> Color:
	return seat_color(seat).lerp(Color("d9d6cc"), 0.72)
