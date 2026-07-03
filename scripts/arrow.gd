class_name Arrow
extends Node2D

var cells: Array = []  # Vector2i cells, tail -> head
var direction: Vector2i
var cell_size: float = 60.0
var arrow_color: Color = Color("#2B3A67")
var highlighted: bool = false
var removing: bool = false

# Path the arrow slides along: cell centers tail -> head, then a straight
# off-screen extension in the head's facing direction.
var path_pts: PackedVector2Array = PackedVector2Array()
var body_len: float = 0.0
var total_len: float = 0.0
var slide_offset: float = 0.0:
	set(value):
		slide_offset = value
		queue_redraw()
var flash_amount: float = 0.0:
	set(value):
		flash_amount = value
		queue_redraw()

func setup(p_cells: Array, p_direction: Vector2i, p_cell_size: float, p_points: PackedVector2Array, exit_clearance: float):
	cells = p_cells
	direction = p_direction
	cell_size = p_cell_size

	path_pts = p_points.duplicate()
	body_len = 0.0
	for i in range(p_points.size() - 1):
		body_len += p_points[i].distance_to(p_points[i + 1])

	var head_pt = p_points[p_points.size() - 1]
	path_pts.append(head_pt + Vector2(direction) * (exit_clearance + body_len))

	total_len = 0.0
	for i in range(path_pts.size() - 1):
		total_len += path_pts[i].distance_to(path_pts[i + 1])

func _draw():
	var color = Color("#4A9FE8") if highlighted else arrow_color
	if flash_amount > 0.0:
		color = color.lerp(Color("#E8455A"), flash_amount)
	var line_w = cell_size * 0.22
	var head_len = cell_size * 0.46
	var head_half_w = cell_size * 0.27

	var s_head = slide_offset + body_len
	var head_pos = _point_at(s_head)
	var dirv = Vector2(direction).normalized()  # diagonal dirs have length sqrt(2)

	# Body line, stopping at the arrowhead base
	var line_end = s_head - head_len * 0.4
	if line_end > slide_offset:
		var pts = _sub_path(slide_offset, line_end)
		if pts.size() >= 2:
			draw_polyline(pts, color, line_w, true)
		# Round caps and rounded corners at bends
		for p in pts:
			draw_circle(p, line_w * 0.5, color)

	# Arrowhead triangle
	var tip = head_pos + dirv * head_len * 0.55
	var base = head_pos - dirv * head_len * 0.45
	var perp = Vector2(-dirv.y, dirv.x)
	draw_colored_polygon(PackedVector2Array([
		tip,
		base + perp * head_half_w,
		base - perp * head_half_w,
	]), color)

func _point_at(s: float) -> Vector2:
	var remaining = clampf(s, 0.0, total_len)
	for i in range(path_pts.size() - 1):
		var seg = path_pts[i + 1] - path_pts[i]
		var seg_len = seg.length()
		if remaining <= seg_len:
			return path_pts[i] + seg * (remaining / seg_len)
		remaining -= seg_len
	return path_pts[path_pts.size() - 1]

func _sub_path(s0: float, s1: float) -> PackedVector2Array:
	var pts = PackedVector2Array()
	pts.append(_point_at(s0))
	var acc = 0.0
	for i in range(1, path_pts.size()):
		acc += path_pts[i].distance_to(path_pts[i - 1])
		if acc > s0 and acc < s1:
			pts.append(path_pts[i])
	pts.append(_point_at(s1))
	return pts

func set_highlighted(val: bool):
	highlighted = val
	queue_redraw()

func animate_escape(on_done: Callable):
	removing = true
	var travel = total_len - body_len
	var duration = clampf(travel / 1800.0, 0.3, 0.6)
	var tween = create_tween()
	tween.tween_property(self, "slide_offset", travel, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.15) \
		.set_delay(duration - 0.15)
	tween.tween_callback(on_done)

# Slide forward until bumping the blocker, flash red, slide back.
func animate_blocked(bump_px: float):
	var tween = create_tween()
	tween.tween_property(self, "slide_offset", bump_px, 0.1) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "flash_amount", 1.0, 0.1)
	tween.tween_property(self, "slide_offset", 0.0, 0.22) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(self, "flash_amount", 0.0, 0.22)
