class_name LevelGenerator

const DIRECTIONS = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const DIAGONALS = [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
const DIAGONALS_FROM_LEVEL = 25

# Arrows are "snakes": an ordered list of cells (tail -> head) that can bend.
# Tapping one slides the whole arrow along its own path, the head leading
# straight out in its facing direction. It escapes if the straight ray from
# the head to the grid edge is free of other arrows.
static func generate(level_num: int) -> Dictionary:
	if level_num == 1:
		return _level_one()

	var rng = RandomNumberGenerator.new()
	rng.seed = level_num * 73856093 + 19349669

	var config = _get_level_config(level_num)
	var grid_size: Vector2i = config.grid_size
	var target_cells = int(config.fill * grid_size.x * grid_size.y)

	var occupied: Dictionary = {}
	var arrows: Array = []

	# Diagonal arrows are a rare accent: exactly 1 from level 25, one more
	# every 75 levels, never more than 5 - always far fewer than orthogonals.
	var diag_quota = 0
	if level_num >= DIAGONALS_FROM_LEVEL:
		diag_quota = clampi(1 + (level_num - DIAGONALS_FROM_LEVEL) / 75, 1, 5)
	var diag_placed = 0

	# Reverse construction: each arrow placed has a clear exit ray relative to
	# the arrows already on the board, so removing them in reverse placement
	# order always solves the level. Arrows are added until the board reaches
	# the target density (or placement stops finding room).
	var fails = 0
	while occupied.size() < target_cells and fails < 400:
		var head = Vector2i(rng.randi_range(0, grid_size.x - 1), rng.randi_range(0, grid_size.y - 1))
		if occupied.has(head):
			fails += 1
			continue

		var placed = false
		var dirs = DIRECTIONS.duplicate()
		_shuffle(dirs, rng)
		# Pace diagonals: at most one per ~6 arrows placed so far, so they stay
		# a small minority even on boards with few (long) arrows
		if diag_placed < diag_quota and diag_placed * 6 <= arrows.size() and rng.randf() < 0.35:
			var diags = DIAGONALS.duplicate()
			_shuffle(diags, rng)
			dirs = diags + dirs  # try a diagonal first, fall back to orthogonal
		for dir in dirs:
			if not _ray_clear(head, dir, occupied, grid_size):
				continue
			var cells = _grow_body(head, dir, occupied, grid_size, rng, config)
			if cells.size() < 2:
				continue
			for c in cells:
				occupied[c] = true
			arrows.append({"cells": cells, "dir": dir})
			if dir.x != 0 and dir.y != 0:
				diag_placed += 1
			placed = true
			break
		if placed:
			fails = 0
		else:
			fails += 1

	var solution_order: Array = []
	for i in range(arrows.size()):
		solution_order.append(i)
	solution_order.reverse()

	return {
		"grid_size": grid_size,
		"arrows": arrows,
		"solution": solution_order,
		"difficulty": config.difficulty,
		"level": level_num,
	}

static func _level_one() -> Dictionary:
	# Tutorial layout: three straight arrows pointing up, side by side.
	var arrows: Array = []
	for x in range(3):
		arrows.append({
			"cells": [Vector2i(x, 2), Vector2i(x, 1), Vector2i(x, 0)],
			"dir": Vector2i.UP,
		})
	return {
		"grid_size": Vector2i(3, 3),
		"arrows": arrows,
		"solution": [2, 1, 0],
		"difficulty": "Easy",
		"level": 1,
	}

# Grow the arrow body backwards from the head. Returns cells ordered tail -> head.
# The cell behind the head must align with the facing direction; after that the
# body may turn. Body cells never sit on the head's exit ray, so an arrow can
# never block itself.
static func _grow_body(head: Vector2i, dir: Vector2i, occupied: Dictionary, grid_size: Vector2i, rng: RandomNumberGenerator, config: Dictionary) -> Array:
	var cells: Array = [head]
	# Mix of vastly different sizes: some short stubs, mostly long winding arrows
	var target_len: int
	if rng.randf() < 0.25:
		target_len = rng.randi_range(2, 3)
	else:
		target_len = rng.randi_range(3, config.max_len)
	var cur = head
	var travel = -dir

	while cells.size() < target_len:
		var options: Array
		if cells.size() == 1:
			options = [travel]
		else:
			var turns = [Vector2i(travel.y, travel.x), Vector2i(-travel.y, -travel.x)]
			_shuffle(turns, rng)
			if rng.randf() < config.bend_chance:
				options = turns + [travel]
			else:
				options = [travel] + turns

		var moved = false
		for d in options:
			var nc = cur + d
			if nc.x < 0 or nc.x >= grid_size.x or nc.y < 0 or nc.y >= grid_size.y:
				continue
			if occupied.has(nc):
				continue
			if cells.has(nc):
				continue
			if _on_exit_ray(nc, head, dir):
				continue
			if d.x != 0 and d.y != 0:
				# Diagonal body step must not cross other arrows or itself
				var c1 = Vector2i(cur.x, nc.y)
				var c2 = Vector2i(nc.x, cur.y)
				if (occupied.has(c1) or cells.has(c1)) and (occupied.has(c2) or cells.has(c2)):
					continue
			cur = nc
			travel = d
			cells.append(nc)
			moved = true
			break
		if not moved:
			break

	cells.reverse()
	return cells

# True if cell = head + k*dir for some k > 0. Works for orthogonal and
# diagonal directions: collinear (zero cross product) and ahead (positive dot).
static func _on_exit_ray(cell: Vector2i, head: Vector2i, dir: Vector2i) -> bool:
	var delta = cell - head
	return delta.x * dir.y == delta.y * dir.x and delta.x * dir.x + delta.y * dir.y > 0

# A diagonal step from a to b passes between two corner cells; if both are
# occupied the arrows would visually cross/overlap, so the step is blocked.
static func _corners_blocked(a: Vector2i, b: Vector2i, occupied: Dictionary) -> bool:
	return occupied.has(Vector2i(a.x, b.y)) and occupied.has(Vector2i(b.x, a.y))

static func _ray_clear(head: Vector2i, dir: Vector2i, occupied: Dictionary, grid_size: Vector2i) -> bool:
	var is_diag = dir.x != 0 and dir.y != 0
	var prev = head
	var check = head + dir
	while check.x >= 0 and check.x < grid_size.x and check.y >= 0 and check.y < grid_size.y:
		if occupied.has(check):
			return false
		if is_diag and _corners_blocked(prev, check, occupied):
			return false
		prev = check
		check += dir
	return true

static func _shuffle(arr: Array, rng: RandomNumberGenerator):
	for i in range(arr.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp

# The board itself is the main difficulty axis: it grows quickly level by
# level while cells render at max size, fills the screen around level ~20,
# then keeps gaining cells as the view "zooms out" (smaller cells), until
# cells hit the minimum comfortable tap size at 13x16.
static func _get_level_config(level_num: int) -> Dictionary:
	# Steep ramp: cell count grows ~1.5x per level early on, capping at 13x16
	# by level 20 (previously the cap arrived around level 100).
	var grid_size: Vector2i
	if level_num <= 2:
		grid_size = Vector2i(4, 4)
	elif level_num == 3:
		grid_size = Vector2i(5, 5)
	elif level_num == 4:
		grid_size = Vector2i(5, 6)
	elif level_num == 5:
		grid_size = Vector2i(6, 7)
	elif level_num == 6:
		grid_size = Vector2i(7, 8)
	elif level_num == 7:
		grid_size = Vector2i(8, 9)
	elif level_num == 8:
		grid_size = Vector2i(9, 11)
	elif level_num <= 10:
		grid_size = Vector2i(10, 12)
	elif level_num <= 13:
		grid_size = Vector2i(11, 13)
	elif level_num <= 16:
		grid_size = Vector2i(12, 14)
	elif level_num <= 19:
		grid_size = Vector2i(12, 15)
	else:
		grid_size = Vector2i(13, 16)

	# Boards stay dense at every size; small boards are easy because they
	# are small, not because they are sparse.
	var fill = clampf(0.78 + level_num * 0.02, 0.8, 0.92)

	# Longest arrows grow with level, so stubs and giant snakes coexist
	var max_len = clampi(4 + level_num, 4, grid_size.x + grid_size.y)
	var bend_chance = minf(0.25 + level_num * 0.04, 0.5)

	var difficulty: String
	if level_num <= 4:
		difficulty = "Easy"
	elif level_num <= 12:
		difficulty = "Normal"
	elif level_num <= 40:
		difficulty = "Hard"
	else:
		difficulty = "Expert"

	return {
		"grid_size": grid_size,
		"fill": fill,
		"max_len": max_len,
		"bend_chance": bend_chance,
		"difficulty": difficulty,
	}
