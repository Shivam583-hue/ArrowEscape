extends Node2D

const LEVEL_TIME = 180.0

var level_num: int = 1
var level_data: Dictionary
var grid_size: Vector2i
var cell_size: float
var grid_origin: Vector2
var arrows: Dictionary = {}  # Vector2i -> Arrow node (one entry per covered cell)
var arrow_list: Array = []  # parallel to level_data.arrows
var remaining_count: int = 0
var lives: int = 3
var input_locked: bool = false
var level_won: bool = false
var time_left: float = 0.0

# HUD nodes
var level_label: Label
var progress_label: Label
var timer_label: Label
var coins_value: Label
var hearts: Array = []
var tutorial_label: Label
var timer_pill: Panel
var timer_low: bool = false
var overlay: Control

func _ready():
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP_WIDTH
	level_num = PlayerData.current_level
	lives = PlayerData.lives
	_build_ui()
	_load_level(level_num)

func _process(delta):
	if level_won or overlay.visible or time_left <= 0.0:
		return
	time_left = maxf(time_left - delta, 0.0)
	_update_timer_label()
	if time_left <= 0.0:
		_show_time_up()

func _build_ui():
	var bg = ColorRect.new()
	bg.color = UITheme.MIST
	bg.size = Vector2(480, 854)
	bg.z_index = -1  # keep below this node's own drawing (grid dots)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE  # grid taps arrive via _unhandled_input
	add_child(bg)

	# Top-left: home and restart
	var home_btn = UITheme.icon_button("home", 52, UITheme.SLATE, UITheme.SLATE.darkened(0.25), Color.WHITE)
	home_btn.position = Vector2(18, 18)
	home_btn.pressed.connect(_on_back_pressed)
	add_child(home_btn)

	var restart_btn = UITheme.icon_button("restart", 52, Color.WHITE, Color("#D5DBE6"), UITheme.SLATE)
	restart_btn.position = Vector2(80, 18)
	restart_btn.pressed.connect(func(): _load_level(level_num))
	add_child(restart_btn)

	# Center: level title with hearts underneath
	level_label = UITheme.make_label("Level 1", 30, UITheme.NAVY, 800)
	level_label.position = Vector2(140, 6)
	level_label.size = Vector2(200, 40)
	add_child(level_label)

	hearts.clear()
	var heart_size = 26.0
	var hearts_w = 3 * heart_size + 2 * 10
	for i in range(3):
		var h = UIIcon.new()
		h.icon = "heart"
		h.color = UITheme.RED
		h.position = Vector2(240 - hearts_w / 2.0 + i * (heart_size + 10), 48)
		h.size = Vector2(heart_size, heart_size)
		add_child(h)
		hearts.append(h)

	# Top-right: progress counter with arrow badge
	progress_label = UITheme.make_label("0/0", 22, UITheme.SLATE, 700)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	progress_label.position = Vector2(290, 24)
	progress_label.size = Vector2(114, 32)
	add_child(progress_label)

	var badge = Panel.new()
	badge.position = Vector2(412, 14)
	badge.size = Vector2(50, 50)
	badge.add_theme_stylebox_override("panel", UITheme.rounded(UITheme.SLATE, 16, UITheme.SLATE.darkened(0.25), 4))
	var badge_icon = UIIcon.new()
	badge_icon.icon = "arrow_up"
	badge_icon.color = Color.WHITE
	badge_icon.position = Vector2(12, 10)
	badge_icon.size = Vector2(26, 26)
	badge.add_child(badge_icon)
	add_child(badge)

	# Timer pill
	var pill = Panel.new()
	pill.position = Vector2(184, 84)
	pill.size = Vector2(112, 34)
	pill.add_theme_stylebox_override("panel", UITheme.rounded(UITheme.PILL_GRAY, 17))
	timer_pill = pill
	var clock_icon = UIIcon.new()
	clock_icon.icon = "clock"
	clock_icon.color = Color.WHITE
	clock_icon.position = Vector2(10, 7)
	clock_icon.size = Vector2(20, 20)
	pill.add_child(clock_icon)
	timer_label = UITheme.make_label("03:00", 17, Color.WHITE, 700)
	timer_label.position = Vector2(32, 0)
	timer_label.size = Vector2(70, 34)
	pill.add_child(timer_label)
	add_child(pill)

	# Bottom bar: coins pill and hint button
	var coins_pill = UITheme.stat_pill("coin", UITheme.GOLD, "0", Vector2(124, 44), Color.WHITE, UITheme.NAVY)
	coins_pill.position = Vector2(18, 768)
	add_child(coins_pill)
	coins_value = coins_pill.get_node("Value")

	var hint_btn = UITheme.icon_button("bulb", 64, Color.WHITE, Color("#D5DBE6"), UITheme.GOLD, 0.5)
	hint_btn.position = Vector2(398, 758)
	hint_btn.pressed.connect(_on_hint_pressed)
	add_child(hint_btn)

	# Tutorial hint, level 1 only
	tutorial_label = UITheme.make_label("TAP TO MOVE OUT", 26, UITheme.SLATE_LIGHT, 800)
	tutorial_label.position = Vector2(0, 706)
	tutorial_label.size = Vector2(480, 40)
	add_child(tutorial_label)

	# Full-screen result overlay; content is rebuilt on every show
	overlay = Control.new()
	overlay.size = Vector2(480, 854)
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 10
	add_child(overlay)

func _load_level(level: int):
	level_num = level
	PlayerData.current_level = level
	lives = PlayerData.lives
	input_locked = false
	level_won = false
	time_left = LEVEL_TIME
	overlay.visible = false
	tutorial_label.visible = level == 1

	# Clear old arrows
	for node in arrow_list:
		if is_instance_valid(node):
			node.queue_free()
	arrows.clear()
	arrow_list.clear()

	# Generate level
	level_data = LevelGenerator.generate(level_num)
	grid_size = level_data.grid_size
	remaining_count = level_data.arrows.size()

	# Calculate grid layout (capped cell size so small boards stay compact)
	var game_area = Vector2(460, 560)
	var game_offset = Vector2(10, 140)
	cell_size = min(game_area.x / grid_size.x, game_area.y / grid_size.y, 62.0)
	var grid_pixel_size = Vector2(grid_size.x * cell_size, grid_size.y * cell_size)
	grid_origin = game_offset + (game_area - grid_pixel_size) / 2.0

	# Create arrow nodes
	for i in range(level_data.arrows.size()):
		var arrow_data = level_data.arrows[i]
		var arrow_node = Arrow.new()
		var points = PackedVector2Array()
		for c in arrow_data.cells:
			points.append(_grid_to_screen(c))
		arrow_node.setup(arrow_data.cells, arrow_data.dir, cell_size, points, 1000.0)
		add_child(arrow_node)
		for c in arrow_data.cells:
			arrows[c] = arrow_node
		arrow_list.append(arrow_node)

	_update_hud()
	_update_timer_label()
	queue_redraw()

func _grid_to_screen(grid_pos: Vector2i) -> Vector2:
	return grid_origin + Vector2(grid_pos.x * cell_size + cell_size / 2.0, grid_pos.y * cell_size + cell_size / 2.0)

func _screen_to_grid(screen_pos: Vector2) -> Vector2i:
	var local = screen_pos - grid_origin
	var gx = int(local.x / cell_size)
	var gy = int(local.y / cell_size)
	return Vector2i(gx, gy)

func _draw():
	# Draw grid dots on cells not covered by an arrow
	var dot_radius = clampf(cell_size * 0.07, 3.0, 5.0)
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var pos = Vector2i(x, y)
			if not arrows.has(pos):
				var screen_pos = _grid_to_screen(pos)
				draw_circle(screen_pos, dot_radius, Color("#B4BAC7"))

func _unhandled_input(event):
	if input_locked or overlay.visible:
		return

	var click_pos: Vector2 = Vector2.ZERO
	var is_click = false

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click_pos = event.position
		is_click = true
	elif event is InputEventScreenTouch and event.pressed:
		click_pos = event.position
		is_click = true

	if not is_click:
		return

	var grid_pos = _screen_to_grid(click_pos)
	if grid_pos.x < 0 or grid_pos.x >= grid_size.x or grid_pos.y < 0 or grid_pos.y >= grid_size.y:
		return

	if not arrows.has(grid_pos):
		return

	var arrow: Arrow = arrows[grid_pos]
	if arrow.removing:
		return

	if _is_arrow_free(arrow):
		_escape_arrow(arrow)
	else:
		_wrong_tap(arrow)

func _is_arrow_free(arrow: Arrow) -> bool:
	var is_diag = arrow.direction.x != 0 and arrow.direction.y != 0
	var prev: Vector2i = arrow.cells.back()
	var check: Vector2i = prev + arrow.direction
	while check.x >= 0 and check.x < grid_size.x and check.y >= 0 and check.y < grid_size.y:
		if arrows.has(check) and arrows[check] != arrow:
			return false
		if is_diag and _corners_blocked(prev, check, arrow):
			return false
		prev = check
		check += arrow.direction
	return true

# A diagonal step passes between two corner cells; both occupied by OTHER
# arrows means sliding through would visually cross them.
func _corners_blocked(a: Vector2i, b: Vector2i, arrow: Arrow) -> bool:
	var c1 = Vector2i(a.x, b.y)
	var c2 = Vector2i(b.x, a.y)
	return arrows.has(c1) and arrows[c1] != arrow and arrows.has(c2) and arrows[c2] != arrow

func _escape_arrow(arrow: Arrow):
	arrow.removing = true
	for c in arrow.cells:
		arrows.erase(c)
	remaining_count -= 1
	if tutorial_label.visible:
		tutorial_label.visible = false
	_update_hud()
	queue_redraw()

	arrow.animate_escape(func():
		arrow.queue_free()
		_check_win()
	)

func _wrong_tap(arrow: Arrow):
	input_locked = true
	# Slide until the head bumps the first blocker (cell or crossed corner pair)
	var gap = 0
	var is_diag = arrow.direction.x != 0 and arrow.direction.y != 0
	var prev: Vector2i = arrow.cells.back()
	var check: Vector2i = prev + arrow.direction
	while check.x >= 0 and check.x < grid_size.x and check.y >= 0 and check.y < grid_size.y:
		if arrows.has(check) and arrows[check] != arrow:
			break
		if is_diag and _corners_blocked(prev, check, arrow):
			break
		gap += 1
		prev = check
		check += arrow.direction
	# Diagonal steps cover sqrt(2) cells worth of pixels
	var step = cell_size * Vector2(arrow.direction).length()
	arrow.animate_blocked(gap * step + step * 0.3)
	lives = PlayerData.lose_life()
	_update_hud()

	await get_tree().create_timer(0.4).timeout
	input_locked = false

	if lives <= 0:
		_show_game_over()

func _check_win():
	# Every escaping arrow's animation callback lands here; guard so the win
	# fires once even when the last two arrows are animating simultaneously
	if remaining_count > 0 or level_won:
		return
	level_won = true
	input_locked = true
	PlayerData.complete_level(level_num)
	await get_tree().create_timer(0.4).timeout
	_show_level_complete()

func _update_hud():
	level_label.text = "Level %d" % level_num
	var total = level_data.arrows.size() if level_data else 0
	progress_label.text = "%d/%d" % [total - remaining_count, total]
	coins_value.text = str(PlayerData.coins)
	for i in range(3):
		hearts[i].color = UITheme.RED if i < lives else UITheme.HEART_OFF

func _update_timer_label():
	var t = int(ceilf(time_left))
	timer_label.text = "%02d:%02d" % [t / 60, t % 60]
	var low = time_left <= 30.0 and time_left > 0.0
	if low != timer_low:
		timer_low = low
		var pill_color = UITheme.RED if low else UITheme.PILL_GRAY
		timer_pill.add_theme_stylebox_override("panel", UITheme.rounded(pill_color, 17))

# --- Result screens (full-screen, rebuilt each time they are shown) ---

func _open_screen() -> Control:
	for c in overlay.get_children():
		c.queue_free()
	var dim = ColorRect.new()
	dim.color = UITheme.INK
	dim.size = Vector2(480, 854)
	overlay.add_child(dim)
	overlay.visible = true
	return overlay

func _add_home_and_coins(screen: Control):
	var home_btn = UITheme.icon_button("home", 48, Color("#2A3355"), Color("#1F2742"), Color.WHITE)
	home_btn.position = Vector2(18, 20)
	home_btn.pressed.connect(_on_back_pressed)
	screen.add_child(home_btn)

	var coins_pill = UITheme.stat_pill("coin", UITheme.GOLD, str(PlayerData.coins), Vector2(124, 44), Color("#2A3355"), Color.WHITE)
	coins_pill.position = Vector2(338, 22)
	screen.add_child(coins_pill)

func _show_level_complete():
	var screen = _open_screen()
	_add_home_and_coins(screen)

	# Star burst over the title
	for star in [[140.0, 172.0, 42.0], [210.0, 140.0, 60.0], [298.0, 172.0, 42.0]]:
		var st = UIIcon.new()
		st.icon = "star"
		st.color = UITheme.GOLD
		st.position = Vector2(star[0], star[1])
		st.size = Vector2(star[2], star[2])
		screen.add_child(st)

	var title = UITheme.make_label("WELL DONE!", 52, UITheme.GOLD, 800)
	title.position = Vector2(0, 232)
	title.size = Vector2(480, 70)
	screen.add_child(title)

	var lvl = UITheme.make_label("Level %d" % level_num, 28, Color.WHITE, 700)
	lvl.position = Vector2(0, 330)
	lvl.size = Vector2(480, 40)
	screen.add_child(lvl)

	var reward = HBoxContainer.new()
	reward.position = Vector2(0, 400)
	reward.size = Vector2(480, 44)
	reward.alignment = BoxContainer.ALIGNMENT_CENTER
	reward.add_theme_constant_override("separation", 10)
	var amount = UITheme.make_label("+%d" % PlayerData.COINS_PER_LEVEL, 32, Color.WHITE, 700)
	reward.add_child(amount)
	var coin = UIIcon.new()
	coin.icon = "coin"
	coin.color = UITheme.GOLD
	coin.color2 = UITheme.GOLD_LIGHT
	coin.custom_minimum_size = Vector2(34, 34)
	reward.add_child(coin)
	screen.add_child(reward)

	var next_btn = UITheme.solid_button("Next", Vector2(280, 64), UITheme.GREEN, UITheme.GREEN_DARK, 26)
	next_btn.position = Vector2(100, 510)
	next_btn.pressed.connect(func():
		if level_num >= 1000:
			_on_back_pressed()
		else:
			_load_level(level_num + 1)
	)
	screen.add_child(next_btn)

	var select_btn = UITheme.flat_text_button("Level select", 18, Color(1, 1, 1, 0.75))
	select_btn.position = Vector2(160, 600)
	select_btn.size = Vector2(160, 36)
	select_btn.pressed.connect(_on_back_pressed)
	screen.add_child(select_btn)

func _show_game_over():
	input_locked = true
	var screen = _open_screen()
	_add_home_and_coins(screen)

	var hearts_w = 3 * 40 + 2 * 14
	for i in range(3):
		var h = UIIcon.new()
		h.icon = "heart"
		h.color = Color("#3A4468")
		h.position = Vector2(240 - hearts_w / 2.0 + i * 54, 170)
		h.size = Vector2(40, 40)
		screen.add_child(h)

	var title = UITheme.make_label("OUT OF LIVES", 44, UITheme.RED, 800)
	title.position = Vector2(0, 240)
	title.size = Vector2(480, 60)
	screen.add_child(title)

	var msg = UITheme.make_label("", 19, Color(1, 1, 1, 0.85), 600)
	msg.position = Vector2(60, 320)
	msg.size = Vector2(360, 80)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	screen.add_child(msg)

	if PlayerData.coins >= PlayerData.LIVES_COST:
		msg.text = "Refill your lives and keep going?"
		var buy_btn = UITheme.solid_button("Refill lives - %d" % PlayerData.LIVES_COST, Vector2(300, 62), UITheme.GOLD, UITheme.GOLD_DARK, 22)
		buy_btn.position = Vector2(90, 450)
		buy_btn.pressed.connect(func():
			if PlayerData.buy_lives():
				lives = PlayerData.lives
				overlay.visible = false
				input_locked = false
				_update_hud()
		)
		screen.add_child(buy_btn)

		var select_btn = UITheme.flat_text_button("Level select", 18, Color(1, 1, 1, 0.75))
		select_btn.position = Vector2(160, 540)
		select_btn.size = Vector2(160, 36)
		select_btn.pressed.connect(_on_back_pressed)
		screen.add_child(select_btn)
	else:
		var mins = int(ceilf(PlayerData.get_time_until_refill() / 60.0))
		msg.text = "Lives refill in %d min.\nCome back soon!" % mins
		var menu_btn = UITheme.solid_button("Level select", Vector2(280, 62), UITheme.GREEN, UITheme.GREEN_DARK, 24)
		menu_btn.position = Vector2(100, 450)
		menu_btn.pressed.connect(_on_back_pressed)
		screen.add_child(menu_btn)

func _show_time_up():
	input_locked = true
	var screen = _open_screen()
	_add_home_and_coins(screen)

	var clock = UIIcon.new()
	clock.icon = "clock"
	clock.color = Color.WHITE
	clock.position = Vector2(208, 150)
	clock.size = Vector2(64, 64)
	screen.add_child(clock)

	var title = UITheme.make_label("TIME'S UP", 46, UITheme.GOLD, 800)
	title.position = Vector2(0, 240)
	title.size = Vector2(480, 60)
	screen.add_child(title)

	var lvl = UITheme.make_label("Level %d" % level_num, 26, Color.WHITE, 700)
	lvl.position = Vector2(0, 320)
	lvl.size = Vector2(480, 40)
	screen.add_child(lvl)

	var retry_btn = UITheme.solid_button("Try again", Vector2(280, 64), UITheme.GREEN, UITheme.GREEN_DARK, 26)
	retry_btn.position = Vector2(100, 450)
	retry_btn.pressed.connect(func(): _load_level(level_num))
	screen.add_child(retry_btn)

	var select_btn = UITheme.flat_text_button("Level select", 18, Color(1, 1, 1, 0.75))
	select_btn.position = Vector2(160, 540)
	select_btn.size = Vector2(160, 36)
	select_btn.pressed.connect(_on_back_pressed)
	screen.add_child(select_btn)

func _on_hint_pressed():
	if input_locked or overlay.visible:
		return
	# Clear previous highlights
	for arrow in arrow_list:
		if is_instance_valid(arrow) and not arrow.removing:
			arrow.set_highlighted(false)

	# Find a free arrow
	for arrow in arrow_list:
		if not is_instance_valid(arrow) or arrow.removing:
			continue
		if _is_arrow_free(arrow):
			arrow.set_highlighted(true)
			return

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
