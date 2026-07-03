class_name UIIcon
extends Control

# Vector icons drawn with the same stroke language as the game arrows:
# thick lines, round caps, filled heads. Scales to the control's size.

var icon: String = "heart":
	set(value):
		icon = value
		queue_redraw()
var color: Color = Color("#2B3A67"):
	set(value):
		color = value
		queue_redraw()
var color2: Color = Color(0, 0, 0, 0):  # secondary (holes, rings, bases)
	set(value):
		color2 = value
		queue_redraw()

func _init():
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw():
	var s = minf(size.x, size.y)
	var off = (size - Vector2(s, s)) / 2.0
	match icon:
		"home": _home(s, off)
		"restart": _restart(s, off)
		"heart": _heart(s, off)
		"clock": _clock(s, off)
		"bulb": _bulb(s, off)
		"coin": _coin(s, off)
		"arrow_up": _arrow_up(s, off)
		"star": _star(s, off)
		"lock": _lock(s, off)
		"chev_left": _chev(s, off, -1)
		"chev_right": _chev(s, off, 1)

func _p(s: float, off: Vector2, x: float, y: float) -> Vector2:
	return off + Vector2(x, y) * s

func _home(s: float, off: Vector2):
	draw_colored_polygon(PackedVector2Array([
		_p(s, off, 0.5, 0.03), _p(s, off, 1.0, 0.5), _p(s, off, 0.0, 0.5),
	]), color)
	draw_rect(Rect2(_p(s, off, 0.16, 0.48), Vector2(0.68, 0.47) * s), color)
	if color2.a > 0.0:
		draw_rect(Rect2(_p(s, off, 0.41, 0.62), Vector2(0.18, 0.33) * s), color2)

func _restart(s: float, off: Vector2):
	var c = _p(s, off, 0.5, 0.54)
	var r = 0.34 * s
	var w = 0.13 * s
	var a0 = -PI * 0.82
	var a1 = PI * 0.62
	draw_arc(c, r, a0, a1, 28, color, w, true)
	draw_circle(c + Vector2(cos(a1), sin(a1)) * r, w * 0.5, color)
	# Arrowhead at the arc start, pointing along the tangent
	var tip_base = c + Vector2(cos(a0), sin(a0)) * r
	var tangent = Vector2(sin(a0), -cos(a0))
	var normal = Vector2(cos(a0), sin(a0))
	draw_colored_polygon(PackedVector2Array([
		tip_base + tangent * 0.24 * s,
		tip_base + normal * 0.15 * s,
		tip_base - normal * 0.15 * s,
	]), color)

func _heart(s: float, off: Vector2):
	draw_circle(_p(s, off, 0.29, 0.34), 0.26 * s, color)
	draw_circle(_p(s, off, 0.71, 0.34), 0.26 * s, color)
	draw_colored_polygon(PackedVector2Array([
		_p(s, off, 0.06, 0.46), _p(s, off, 0.94, 0.46), _p(s, off, 0.5, 0.95),
	]), color)

func _clock(s: float, off: Vector2):
	var c = _p(s, off, 0.5, 0.58)
	var r = 0.3 * s
	var w = 0.1 * s
	draw_arc(c, r, 0, TAU, 32, color, w, true)
	# Stem and top button
	draw_line(_p(s, off, 0.5, 0.28), _p(s, off, 0.5, 0.14), color, w, true)
	draw_line(_p(s, off, 0.36, 0.08), _p(s, off, 0.64, 0.08), color, w, true)
	# Hands
	draw_line(c, c + Vector2(0, -0.16 * s), color, w * 0.85, true)
	draw_line(c, c + Vector2(0.13 * s, 0.04 * s), color, w * 0.85, true)

func _bulb(s: float, off: Vector2):
	draw_circle(_p(s, off, 0.5, 0.38), 0.3 * s, color)
	var base_col = color2 if color2.a > 0.0 else color.darkened(0.35)
	draw_rect(Rect2(_p(s, off, 0.36, 0.7), Vector2(0.28, 0.12) * s), base_col)
	draw_rect(Rect2(_p(s, off, 0.4, 0.86), Vector2(0.2, 0.09) * s), base_col)

func _coin(s: float, off: Vector2):
	var c = _p(s, off, 0.5, 0.5)
	draw_circle(c, 0.46 * s, color)
	var ring = color2 if color2.a > 0.0 else color.lightened(0.35)
	draw_arc(c, 0.3 * s, 0, TAU, 32, ring, 0.09 * s, true)

func _arrow_up(s: float, off: Vector2):
	var w = 0.17 * s
	draw_line(_p(s, off, 0.5, 0.88), _p(s, off, 0.5, 0.42), color, w, true)
	draw_circle(_p(s, off, 0.5, 0.88), w * 0.5, color)
	draw_colored_polygon(PackedVector2Array([
		_p(s, off, 0.5, 0.05), _p(s, off, 0.18, 0.48), _p(s, off, 0.82, 0.48),
	]), color)

func _star(s: float, off: Vector2):
	var c = _p(s, off, 0.5, 0.54)
	var pts = PackedVector2Array()
	for i in range(10):
		var r = (0.5 if i % 2 == 0 else 0.22) * s
		var a = -PI / 2.0 + i * PI / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, color)

func _lock(s: float, off: Vector2):
	var w = 0.12 * s
	draw_arc(_p(s, off, 0.5, 0.42), 0.21 * s, PI, TAU, 20, color, w, true)
	draw_rect(Rect2(_p(s, off, 0.18, 0.42), Vector2(0.64, 0.5) * s), color)
	if color2.a > 0.0:
		draw_circle(_p(s, off, 0.5, 0.63), 0.09 * s, color2)

func _chev(s: float, off: Vector2, dir: int):
	var w = 0.15 * s
	var x0 = 0.62 if dir < 0 else 0.38
	var x1 = 0.36 if dir < 0 else 0.64
	var a = _p(s, off, x0, 0.18)
	var b = _p(s, off, x1, 0.5)
	var c = _p(s, off, x0, 0.82)
	draw_line(a, b, color, w, true)
	draw_line(b, c, color, w, true)
	for pt in [a, b, c]:
		draw_circle(pt, w * 0.5, color)
