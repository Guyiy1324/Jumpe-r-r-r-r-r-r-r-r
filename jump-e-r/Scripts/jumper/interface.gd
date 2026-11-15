extends RefCounted

const PIXEL := preload("res://Assets/brackeys_platformer_assets/fonts/PixelOperator8-Bold.ttf")
const INK := Color("#101523")
const PANEL := Color("#191f31")
const LINE := Color("#35415c")
const WHITE := Color("#eff3ff")
const MUTED := Color("#aab8d4")
const MINT := Color("#79f0cb")
const GOLD := Color("#ffd18a")


static func box(fill: Color, border := Color.TRANSPARENT, radius := 12, padding := 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(padding)
	return style


static func theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 17
	for type in [&"Button", &"OptionButton", &"CheckButton"]:
		result.set_stylebox("normal", type, box(Color("#222a41"), LINE, 8, 10))
		result.set_stylebox("hover", type, box(Color("#303d59"), Color("#596888"), 8, 10))
		result.set_stylebox("pressed", type, box(Color("#294c4d"), MINT, 8, 10))
		result.set_stylebox("disabled", type, box(Color("#1b2233"), Color("#2a344b"), 8, 10))
		result.set_stylebox("focus", type, box(Color.TRANSPARENT, MINT, 8))
		result.set_color("font_color", type, WHITE)
		result.set_color("font_hover_color", type, WHITE)
		result.set_color("font_pressed_color", type, MINT)
		result.set_color("font_disabled_color", type, Color("#7d8da8"))
	result.set_stylebox("panel", "PanelContainer", box(PANEL, LINE, 12, 16))
	result.set_stylebox("normal", "LineEdit", box(INK, LINE, 8, 9))
	result.set_stylebox("focus", "LineEdit", box(INK, MINT, 8, 9))
	result.set_color("font_color", "LineEdit", WHITE)
	result.set_color("font_color", "Label", WHITE)
	result.set_stylebox("panel", "PopupMenu", box(PANEL, LINE, 8, 8))
	result.set_stylebox("hover", "PopupMenu", box(Color("#303d59"), LINE, 5))
	result.set_stylebox("panel", "AcceptDialog", box(PANEL, LINE, 12, 20))
	return result


static func label(copy: String, font_size := 17, tint := WHITE, pixel := false) -> Label:
	var node := Label.new()
	node.text = copy
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", tint)
	if pixel:
		node.add_theme_font_override("font", PIXEL)
	return node


static func button(copy: String, action: Callable, primary := false, height := 42) -> Button:
	var node := Button.new()
	node.text = copy
	node.custom_minimum_size.y = height
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if action.is_valid():
		node.pressed.connect(action)
	if primary:
		node.add_theme_stylebox_override("normal", box(MINT, MINT, 8, 11))
		node.add_theme_stylebox_override("hover", box(Color("#a9ffe5"), MINT, 8, 11))
		node.add_theme_stylebox_override("pressed", box(Color("#4bba9a"), MINT, 8, 11))
		node.add_theme_stylebox_override("focus", box(Color.TRANSPARENT, WHITE, 8))
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			node.add_theme_color_override(state, Color("#102c2b"))
	return node


static func vbox(gap := 12) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.add_theme_constant_override("separation", gap)
	return node


static func hbox(gap := 12) -> HBoxContainer:
	var node := HBoxContainer.new()
	node.add_theme_constant_override("separation", gap)
	return node


static func spacer(vertical := false) -> Control:
	var node := Control.new()
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if vertical:
		node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node


static func panel(fill := PANEL, border := LINE, padding := 16) -> PanelContainer:
	var node := PanelContainer.new()
	node.add_theme_stylebox_override("panel", box(fill, border, 12, padding))
	return node


static func margins(parent: Control, horizontal: int, vertical: int) -> MarginContainer:
	var node := MarginContainer.new()
	parent.add_child(node)
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		node.add_theme_constant_override("margin_" + side, horizontal)
	for side in ["top", "bottom"]:
		node.add_theme_constant_override("margin_" + side, vertical)
	return node


static func key_hint(copy: String) -> PanelContainer:
	var node := panel(Color("#222a41"), LINE, 7)
	node.add_child(label(copy, 13, MUTED))
	return node
