class_name UITheme

# One visual system for the whole game: mist board, arrow navy, candy buttons
const MIST = Color("#E9EDF4")
const NAVY = Color("#2B3A67")
const SLATE = Color("#5B6B85")
const SLATE_LIGHT = Color("#99A3B5")
const RED = Color("#FF4D5E")
const GREEN = Color("#3FBF7F")
const GREEN_DARK = Color("#2F9C65")
const GOLD = Color("#FFB933")
const GOLD_DARK = Color("#DE9A15")
const GOLD_LIGHT = Color("#FFD97A")
const INK = Color("#1B2340")
const HEART_OFF = Color("#C9D0DC")
const PILL_GRAY = Color("#8E99AC")

static var _font_cache: Dictionary = {}

# 'wght' OpenType axis tag as integer; string keys are not matched at runtime
const WGHT_TAG = 2003265652

static func font(weight: int) -> FontVariation:
	if not _font_cache.has(weight):
		var fv = FontVariation.new()
		fv.base_font = load("res://assets/fonts/Baloo2.ttf")
		fv.variation_opentype = {WGHT_TAG: weight}
		_font_cache[weight] = fv
	return _font_cache[weight]

static func style_label(l: Label, font_size: int, color: Color, weight: int = 600):
	l.add_theme_font_override("font", font(weight))
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)

static func make_label(text: String, font_size: int, color: Color, weight: int = 600) -> Label:
	var l = Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	style_label(l, font_size, color, weight)
	return l

static func rounded(bg: Color, radius: int, edge_color: Color = Color.TRANSPARENT, edge: int = 0) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	if edge > 0:
		s.border_width_bottom = edge
		s.border_color = edge_color
	return s

static func shadowed(style: StyleBoxFlat, shadow_size: int = 6) -> StyleBoxFlat:
	style.shadow_color = Color(NAVY, 0.14)
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(0, 3)
	return style

# Candy button: solid fill, darker bottom edge, sinks when pressed
static func solid_button(text: String, sz: Vector2, bg: Color, edge: Color, font_size: int = 24) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = sz
	b.size = sz
	var radius = int(sz.y * 0.3)
	var normal = rounded(bg, radius, edge, 5)
	var hover = rounded(bg.lightened(0.05), radius, edge, 5)
	var pressed = rounded(bg.darkened(0.05), radius)
	pressed.content_margin_top = 5.0
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_font_override("font", font(700))
	b.add_theme_font_size_override("font_size", font_size)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, Color.WHITE)
	return b

static func icon_button(icon_name: String, sz: float, bg: Color, edge: Color, icon_color: Color, round_ratio: float = 0.32) -> Button:
	var b = Button.new()
	b.custom_minimum_size = Vector2(sz, sz)
	b.size = Vector2(sz, sz)
	var radius = int(sz * round_ratio)
	var pressed = rounded(bg.darkened(0.05), radius)
	b.add_theme_stylebox_override("normal", rounded(bg, radius, edge, 4))
	b.add_theme_stylebox_override("hover", rounded(bg.lightened(0.05), radius, edge, 4))
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var ic = UIIcon.new()
	ic.icon = icon_name
	ic.color = icon_color
	if icon_name == "home":
		ic.color2 = bg
	ic.position = Vector2(sz * 0.22, sz * 0.2)
	ic.size = Vector2(sz * 0.56, sz * 0.56)
	b.add_child(ic)
	return b

static func flat_text_button(text: String, font_size: int, color: Color) -> Button:
	var b = Button.new()
	b.text = text
	b.flat = true
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_font_override("font", font(600))
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", color)
	b.add_theme_color_override("font_hover_color", color.lightened(0.2))
	b.add_theme_color_override("font_pressed_color", color)
	return b

# White capsule with an icon and a text label, e.g. coins display.
# Panel (not PanelContainer) so children keep their manual positions.
static func stat_pill(icon_name: String, icon_color: Color, text: String, sz: Vector2, bg: Color, text_color: Color) -> Panel:
	var p = Panel.new()
	p.custom_minimum_size = sz
	p.size = sz
	p.add_theme_stylebox_override("panel", shadowed(rounded(bg, int(sz.y / 2.0)), 4))
	var ic = UIIcon.new()
	ic.icon = icon_name
	ic.color = icon_color
	var icon_size = sz.y * 0.58
	ic.position = Vector2(sz.y * 0.24, (sz.y - icon_size) / 2.0)
	ic.size = Vector2(icon_size, icon_size)
	p.add_child(ic)
	var l = make_label(text, int(sz.y * 0.44), text_color, 700)
	l.name = "Value"
	l.position = Vector2(sz.y * 0.85, 0)
	l.size = Vector2(sz.x - sz.y * 1.0, sz.y)
	p.add_child(l)
	return p
