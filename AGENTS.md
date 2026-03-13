# AGENTS
# Repository guidance for agentic coding tools.
# Keep this file up to date as build/test/lint evolves.

## Quick Facts
- Language: Odin
- Domain: SDL3 game prototype
- Entry point: src/main.odin
- Assets: assets/ (loaded at runtime)
- Rules: no Cursor rules or Copilot rules found in this repo

## Build, Run, Lint, Test
### Run (debug)
- Preferred: `just run`
  - Defined in `justfile` as `odin run src -debug`
- Equivalent: `odin run src -debug`

### Run (non-debug)
- `odin run src`

### Build binary
- `odin build src -out:bin/game`
  - Use `bin/` for built artifacts if needed

### Lint
- None configured yet
- If you add linting later, document commands here

### Tests
- None configured yet
- Single-test execution is not available yet
- If tests are added, include:
  - full test command
  - single-test selector syntax

## Project Layout
- `src/` core game code
  - `main.odin` entry point and logger setup
  - `game.odin` loop, input, update, render
  - `asset_store.odin` texture loading and access
  - `config.odin` constants
- `assets/` runtime assets (e.g., `assets/player.png`)
- `justfile` run task

## Code Style Guidelines
### Files and Modules
- Each file uses `package main`
- Keep one small logical unit per file
- Prefer adding new files to `src/` rather than expanding `main.odin`

### Imports
- Place imports at top of file after `package`
- Use explicit aliases for vendor modules:
  - `import SDL "vendor:sdl3"`
  - `import IMAGE "vendor:sdl3/image"`
  - `import TTF "vendor:sdl3/ttf"`
- Use standard library imports with `core:` prefix (e.g., `core:log`)
- Avoid unused imports

### Formatting
- Use tabs for indentation (consistent with existing code)
- Align struct fields and composite literals vertically when readable
- Keep trailing whitespace out of files
- Favor short, single-line `if` blocks only when they stay readable

### Naming
- Types: PascalCase (`GameState`, `AssetStore`, `Vector2`)
- Functions/procs: snake_case (`handle_events`, `store_add_texture`)
- Variables: snake_case (`ms_prev_frame`, `asset_store`)
- Constants: SCREAMING_SNAKE_CASE (`FRAMES_PER_SECOND`)
- SDL enums: use leading dot (`.QUIT`, `.WINDOW_RESIZED`)

### Types and Data
- Use explicit numeric types for public constants (`u64`, `u8`)
- Use `f32`/`f64` intentionally for SDL interop and math
- Prefer `Vector2` for positions/velocities
- Use pointers (`^Type`) for shared SDL resources

### Error Handling
- Use `assert` for fatal failures during init/load
  - Example: `assert(window != nil, string(SDL.GetError()))`
- For asset loading, fail fast with meaningful messages
- Avoid silent failures in the render path

### Logging
- Logging via `core:log`
- Use `log.infof` for numeric values and state traces
- Keep high-frequency logs behind debug flags if performance matters

### SDL/Resource Management
- Initialize SDL in `initialize()` and quit in `destroy()`
- Always check for `nil` from SDL create calls
- Free surfaces after texture creation (`SDL.free(surface)`)
- Avoid freeing SDL objects that may still be referenced

### Game Loop
- `run()` owns the loop and frame timing
- `update()` should be deterministic and use `dt` (seconds)
- `render()` should not mutate game state
- `handle_events()` should only mutate input/state

### Assets
- Use `asset_store` for all textures/fonts
- Paths are relative to repo root (e.g., `./assets/player.png`)
- Add new asset IDs as stable string keys

### Defensive Checks
- Validate asset existence before render
- Validate pointers before SDL calls
- Prefer asserts in early development

## Conventions for New Code
- Add new constants to `src/config.odin`
- Add new systems as separate files in `src/`
- Keep SDL wrapper logic localized (e.g., input, rendering, assets)
- Use `make_map` for new maps in structs

## Notes for Agents
- There are no test or lint commands yet
- Do not introduce non-ASCII characters unless already present
- If you add tools/configs, update this file with commands
