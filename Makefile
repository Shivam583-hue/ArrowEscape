GODOT ?= godot

.PHONY: run import test apk

run:
	$(GODOT) --path .

apk: import
	mkdir -p build
	$(GODOT) --headless --path . --export-debug "Android" build/ArrowEscape.apk

import:
	$(GODOT) --headless --path . --import

test: import
	$(GODOT) --headless --path . --script res://tests/test_level_generation.gd
