extends Control

const LEVEL_COUNT = 1000
const NODE_SIZE = 64.0
const CURRENT_SIZE = 82.0
const SPACING_Y = 104.0
const PATH_TOP = 70.0
const CENTER_X = 240.0
const AMPLITUDE = 116.0

var scroll_container: ScrollContainer
var path: Control
var no_lives_toast: Panel

func _ready():
	_build_ui()
	_build_path()
	_scroll_to_current.call_deferred()

# Serpentine map: each level sits on a smooth sine wave going down the screen
func _node_center(level: int) -> Vector2:
	return Vector2(
		CENTER_X + sin((level - 1) * 0.55) * AMPLITUDE,
		PATH_TOP + (level - 1) * SPACING_Y
	)

func _build_ui():
	var bg = ColorRect.new()
	bg.color = UITheme.MIST
	bg.size = Vector2(480, 854)
	add_child(bg)

	scroll_container = ScrollContainer.new()
	scroll_container.position = Vector2(0, 150)
	scroll_container.size = Vector2(480, 704)
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	add_child(scroll_container)

	# Header sits above the scrolling map
	var header = Panel.new()
	header.position = Vector2(0, 0)
	header.size = Vector2(480, 150)
	var hs = UITheme.rounded(UITheme.MIST, 0)
	hs.shadow_color = Color(UITheme.NAVY, 0.08)
	hs.shadow_size = 10
	hs.shadow_offset = Vector2(0, 4)
	header.add_theme_stylebox_override("panel", hs)
	add_child(header)

	var coins_pill = UITheme.stat_pill("coin", UITheme.GOLD, str(PlayerData.coins), Vector2(124, 44), Color.WHITE, UITheme.NAVY)
	coins_pill.position = Vector2(18, 18)
	header.add_child(coins_pill)

	var hearts_w = 3 * 24 + 2 * 8
	for i in range(3):
		var h = UIIcon.new()
		h.icon = "heart"
		h.color = UITheme.RED if i < PlayerData.lives else UITheme.HEART_OFF
		h.position = Vector2(462 - hearts_w + i * 32, 28)
		h.size = Vector2(24, 24)
		header.add_child(h)

	var title = UITheme.make_label("ARROW ESCAPE", 34, UITheme.NAVY, 800)
	title.position = Vector2(0, 76)
	title.size = Vector2(480, 44)
	header.add_child(title)

	var subtitle = UITheme.make_label("Level %d" % mini(PlayerData.highest_unlocked, LEVEL_COUNT), 16, UITheme.SLATE_LIGHT, 600)
	subtitle.position = Vector2(0, 118)
	subtitle.size = Vector2(480, 22)
	header.add_child(subtitle)

func _build_path():
	path = Control.new()
	path.custom_minimum_size = Vector2(480, PATH_TOP + (LEVEL_COUNT - 1) * SPACING_Y + 90)
	path.draw.connect(_draw_path)
	scroll_container.add_child(path)

	for level in range(1, LEVEL_COUNT + 1):
		path.add_child(_make_level_node(level))

	if PlayerData.highest_unlocked <= LEVEL_COUNT:
		_add_start_bubble(PlayerData.highest_unlocked)

# The trail behind the nodes: cleared part tinted green, the rest gray
func _draw_path():
	var done_color = Color("#BBDCC9")
	var todo_color = Color("#D8DEE9")
	for level in range(1, LEVEL_COUNT):
		var a = _node_center(level)
		var b = _node_center(level + 1)
		var c = done_color if level < PlayerData.highest_unlocked else todo_color
		path.draw_line(a, b, c, 12.0, true)
		path.draw_circle(a, 6.0, c)

func _make_level_node(level: int) -> Button:
	var is_current = level == PlayerData.highest_unlocked
	var sz = CURRENT_SIZE if is_current else NODE_SIZE
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(sz, sz)
	btn.size = Vector2(sz, sz)
	btn.position = _node_center(level) - Vector2(sz, sz) / 2.0
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_font_override("font", UITheme.font(700))
	btn.add_theme_font_size_override("font_size", 26 if is_current else 22)
	var radius = int(sz / 2.0)

	if is_current:
		# The one green node: where you play next
		btn.text = str(level)
		btn.add_theme_stylebox_override("normal", UITheme.rounded(UITheme.GREEN, radius, UITheme.GREEN_DARK, 6))
		btn.add_theme_stylebox_override("hover", UITheme.rounded(UITheme.GREEN.lightened(0.05), radius, UITheme.GREEN_DARK, 6))
		var pressed = UITheme.rounded(UITheme.GREEN.darkened(0.05), radius)
		pressed.content_margin_top = 6.0
		btn.add_theme_stylebox_override("pressed", pressed)
		for state in ["font_color", "font_hover_color", "font_pressed_color"]:
			btn.add_theme_color_override(state, Color.WHITE)
		btn.pressed.connect(func(): _start_level(level))
	elif level < PlayerData.highest_unlocked:
		# Completed: gold medallion, replayable
		btn.text = str(level)
		btn.add_theme_stylebox_override("normal", UITheme.rounded(UITheme.GOLD, radius, UITheme.GOLD_DARK, 5))
		btn.add_theme_stylebox_override("hover", UITheme.rounded(UITheme.GOLD.lightened(0.05), radius, UITheme.GOLD_DARK, 5))
		var pressed = UITheme.rounded(UITheme.GOLD.darkened(0.05), radius)
		pressed.content_margin_top = 5.0
		btn.add_theme_stylebox_override("pressed", pressed)
		for state in ["font_color", "font_hover_color", "font_pressed_color"]:
			btn.add_theme_color_override(state, Color.WHITE)
		btn.pressed.connect(func(): _start_level(level))
	else:
		# Locked: quiet gray disc with a lock
		btn.disabled = true
		btn.add_theme_stylebox_override("normal", UITheme.rounded(Color("#DEE3EC"), radius, Color("#CDD4E0"), 4))
		btn.add_theme_stylebox_override("disabled", UITheme.rounded(Color("#DEE3EC"), radius, Color("#CDD4E0"), 4))
		var lock = UIIcon.new()
		lock.icon = "lock"
		lock.color = Color("#B4BCCA")
		lock.color2 = Color("#DEE3EC")
		lock.position = Vector2((sz - 24) / 2.0, (sz - 24) / 2.0)
		lock.size = Vector2(24, 24)
		btn.add_child(lock)

	return btn

# Bobbing "START" callout above the current level, Duolingo style
func _add_start_bubble(level: int):
	var center = _node_center(level)
	var bubble = Panel.new()
	bubble.size = Vector2(92, 38)
	bubble.position = center + Vector2(-46, -CURRENT_SIZE / 2.0 - 52)
	bubble.add_theme_stylebox_override("panel", UITheme.shadowed(UITheme.rounded(Color.WHITE, 12), 5))
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l = UITheme.make_label("START", 17, UITheme.GREEN, 800)
	l.size = bubble.size
	bubble.add_child(l)
	path.add_child(bubble)

	var base_y = bubble.position.y
	var tw = bubble.create_tween().set_loops()
	tw.tween_property(bubble, "position:y", base_y - 7.0, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(bubble, "position:y", base_y, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _scroll_to_current():
	var level = mini(PlayerData.highest_unlocked, LEVEL_COUNT)
	var target = _node_center(level).y - scroll_container.size.y * 0.45
	scroll_container.scroll_vertical = int(clamp(target, 0.0, path.custom_minimum_size.y - scroll_container.size.y))

func _start_level(level: int):
	if PlayerData.lives <= 0:
		if PlayerData.get_time_until_refill() <= 0.0:
			PlayerData.reset_lives()
		else:
			_show_no_lives_toast()
			return
	PlayerData.current_level = level
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _show_no_lives_toast():
	if is_instance_valid(no_lives_toast):
		return
	var mins = int(ceilf(PlayerData.get_time_until_refill() / 60.0))
	no_lives_toast = Panel.new()
	no_lives_toast.size = Vector2(300, 46)
	no_lives_toast.position = Vector2(90, 770)
	no_lives_toast.add_theme_stylebox_override("panel", UITheme.rounded(UITheme.NAVY, 23))
	no_lives_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l = UITheme.make_label("Lives refill in %d min" % mins, 17, Color.WHITE, 700)
	l.size = no_lives_toast.size
	no_lives_toast.add_child(l)
	add_child(no_lives_toast)
	var tw = no_lives_toast.create_tween()
	tw.tween_interval(1.6)
	tw.tween_property(no_lives_toast, "modulate:a", 0.0, 0.4)
	tw.tween_callback(no_lives_toast.queue_free)
