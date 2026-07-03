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
				if abs(d.x) + abs(d.y) != 1:
					errs.append("arrow %d not contiguous" % i)
			# Body must not sit on own exit ray
			if j < cells.size() - 1:
				var delta = c - head
				var dir: Vector2i = a.dir
				var on_ray = (delta.x == 0 and delta.y * dir.y > 0) if dir.x == 0 else (delta.y == 0 and delta.x * dir.x > 0)
				if on_ray:
					errs.append("arrow %d self-blocks at %s" % [i, str(c)])
	# Solvability: remove in solution order, each must have clear exit ray
	if data.solution.size() != data.arrows.size():
		errs.append("solution size mismatch")
	var remaining = occupied.duplicate()
	for idx in data.solution:
		var a = data.arrows[idx]
		var check: Vector2i = a.cells.back() + Vector2i(a.dir)
		while check.x >= 0 and check.x < grid.x and check.y >= 0 and check.y < grid.y:
			if remaining.has(check) and remaining[check] != idx:
				errs.append("solution blocked for arrow %d" % idx)
				break
			check += Vector2i(a.dir)
		for c in a.cells:
			remaining.erase(c)
	if remaining.size() > 0:
		errs.append("cells left after solution")
	return errs
