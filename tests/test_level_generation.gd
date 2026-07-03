extends SceneTree

func _initialize():
	var gen = load("res://scripts/level_generator.gd")
	var failures = 0
	var min_arrows = 999
	var stats = {}
	for level in range(1, 1001):
		var data = gen.generate(level)
		var grid: Vector2i = data.grid_size
		var errs = _validate(data, grid)
		# Diagonal arrows: none before 25, then 1..quota and always a small minority
		var diag_count = 0
		for a in data.arrows:
			var dir: Vector2i = a.dir
			if dir.x != 0 and dir.y != 0:
				diag_count += 1
		if level < 25 and diag_count > 0:
			errs.append("diagonals before level 25")
		elif level >= 25:
			var quota = clampi(1 + (level - 25) / 75, 1, 5)
			if diag_count < 1 or diag_count > quota:
				errs.append("diag count %d outside 1..%d" % [diag_count, quota])
			if diag_count * 3 > data.arrows.size():
				errs.append("too many diagonals: %d of %d" % [diag_count, data.arrows.size()])
		if errs.size() > 0:
			failures += 1
			if failures <= 5:
				print("LEVEL %d FAILED: %s" % [level, str(errs)])
		min_arrows = mini(min_arrows, data.arrows.size())
		if level in [1, 2, 5, 10, 15, 20, 27, 40, 100, 500, 1000]:
			var total_cells = 0
			var lens = []
			for a in data.arrows:
				total_cells += a.cells.size()
				lens.append(a.cells.size())
			lens.sort()
			stats[level] = "grid=%s arrows=%d cells=%d/%d lens=%s" % [str(grid), data.arrows.size(), total_cells, grid.x * grid.y, str(lens)]
	for k in stats:
		print("L%s: %s" % [str(k), stats[k]])
	print("min arrows in any level: %d" % min_arrows)
	if failures == 0:
		print("ALL 1000 LEVELS PASS")
	else:
		print("FAILURES: %d" % failures)
	quit()

func _validate(data: Dictionary, grid: Vector2i) -> Array:
	var errs = []
	var occupied = {}
	# Each diagonal segment lives in one unit square; two segments in the same
	# square (necessarily opposite orientations) means a visual crossing.
	var diag_squares = {}
	# Structural checks
	for i in range(data.arrows.size()):
		var a = data.arrows[i]
		var cells: Array = a.cells
		if cells.size() < 2:
			errs.append("arrow %d too short" % i)
		var head: Vector2i = cells.back()
		# Segment behind head must align with facing direction
		if cells.size() >= 2 and cells[cells.size() - 2] != head - Vector2i(a.dir):
			errs.append("arrow %d head segment misaligned" % i)
		for j in range(cells.size()):
			var c: Vector2i = cells[j]
			if c.x < 0 or c.x >= grid.x or c.y < 0 or c.y >= grid.y:
				errs.append("arrow %d cell out of grid" % i)
			if occupied.has(c):
				errs.append("arrow %d overlaps at %s" % [i, str(c)])
			occupied[c] = i
			if j > 0:
				var d: Vector2i = c - cells[j - 1]
				# Steps must be unit-length and of the same kind (orthogonal or
				# diagonal) as the arrow's facing direction
				var dir_i: Vector2i = a.dir
				if maxi(abs(d.x), abs(d.y)) != 1 or abs(d.x) + abs(d.y) != abs(dir_i.x) + abs(dir_i.y):
					errs.append("arrow %d not contiguous" % i)
				if abs(d.x) == 1 and abs(d.y) == 1:
					var square = Vector2i(mini(c.x, cells[j - 1].x), mini(c.y, cells[j - 1].y))
					if diag_squares.has(square):
						errs.append("diagonal segments cross at square %s" % str(square))
					diag_squares[square] = true
			# Body must not sit on own exit ray (collinear with dir and ahead of head)
			if j < cells.size() - 1:
				var delta = c - head
				var dir: Vector2i = a.dir
				if delta.x * dir.y == delta.y * dir.x and delta.x * dir.x + delta.y * dir.y > 0:
					errs.append("arrow %d self-blocks at %s" % [i, str(c)])
	# Solvability: remove in solution order, each must have clear exit ray
	if data.solution.size() != data.arrows.size():
		errs.append("solution size mismatch")
	var remaining = occupied.duplicate()
	for idx in data.solution:
		var a = data.arrows[idx]
		var dir: Vector2i = a.dir
		var is_diag = dir.x != 0 and dir.y != 0
		var prev: Vector2i = a.cells.back()
		var check: Vector2i = prev + dir
		while check.x >= 0 and check.x < grid.x and check.y >= 0 and check.y < grid.y:
			var blocked = remaining.has(check) and remaining[check] != idx
			if not blocked and is_diag:
				# Same rule as the game: sliding between two occupied corner
				# cells belonging to other arrows counts as blocked
				var c1 = Vector2i(prev.x, check.y)
				var c2 = Vector2i(check.x, prev.y)
				blocked = remaining.has(c1) and remaining[c1] != idx \
					and remaining.has(c2) and remaining[c2] != idx
			if blocked:
				errs.append("solution blocked for arrow %d" % idx)
				break
			prev = check
			check += dir
		for c in a.cells:
			remaining.erase(c)
	if remaining.size() > 0:
		errs.append("cells left after solution")
	return errs
