# Arrow Escape

<!-- demo gif goes here -->
<p align="center">
  <img src="docs/demo.gif" alt="Arrow Escape demo" width="300">
</p>

A tap-away arrow puzzle game built with Godot 4.
Arrows are bendy "snakes" packed onto a grid.
Tap one and, if the path from its head to the edge is clear, the whole arrow slides out - body following through every bend.
Clear the board to win.

## Gameplay

- **Tap to escape** - tap any cell of an arrow; if the straight ray from its head to the grid edge is free, it slides out.
- **Blocked arrows bite back** - a blocked arrow bumps into the blocker, flashes red, bounces back, and costs a life.
- **3 lives per level** - run out and it's game over; lives refill after an hour, or buy a refill with coins.
- **180 second timer** - beat the clock or retry (no life cost on timeout).
- **Hints** - the bulb button highlights an arrow that can escape right now.
- **Coins** - earn 40 per cleared level; 300 coins buys 3 lives.

## Features

- 1000 procedurally generated levels, every one guaranteed solvable.
- Reverse-construction generator: arrows are placed with a clear exit relative to already-placed arrows, so the reversed placement order is always a valid solution.
- Seeded RNG - level N is identical for every player, every time.
- Difficulty scales through board size (3x3 tutorial up to 13x16), board density, arrow length (up to 26-cell snakes), and bend frequency.
- Duolingo-style scrolling level-select map with a progress trail across all 1000 levels.
- Smooth tween-based slide, bump-and-bounce, and escape animations.
- Fully code-drawn UI and vector icons - no image assets, export-safe.
- Persistent save data (progress, coins, lives).
- Android export ready (arm64 APK).

## Requirements

- [Godot 4.6](https://godotengine.org/) (GL Compatibility renderer)
- For Android builds: Android SDK, JDK, and Godot Android export templates

## Running

```sh
make run      # launch the game
make import   # headless asset import (needed after adding class_name scripts)
make test     # validate all 1000 levels (structure + solvability)
make apk      # build debug APK -> build/ArrowEscape.apk
```

## Project structure

```
project.godot                    Project config, PlayerData autoload
scenes/
  main_menu.tscn                 Level-select map
  game.tscn                      Gameplay scene
scripts/
  player_data.gd                 Autoload: coins, lives, progress, save/load
  level_generator.gd             Procedural level generation (seeded, solvable)
  arrow.gd                       Snake arrow: polyline drawing, slide/bump animations
  game.gd                        Gameplay: grid, input, HUD, result screens
  main_menu.gd                   Serpentine level map with progress trail
  ui_theme.gd / ui_icon.gd       Code-drawn UI kit and vector icons
tests/
  test_level_generation.gd       Validates all 1000 levels
assets/fonts/Baloo2.ttf          UI font (OFL licensed)
Makefile                         run / import / test / apk targets
```

## Testing

```sh
make test
```

Generates all 1000 levels headlessly and asserts structural validity plus solvability (the stored solution order actually clears each board).

## License

Font: Baloo 2, licensed under the SIL Open Font License (see `assets/fonts/OFL.txt`).
