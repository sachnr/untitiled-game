package main

import store "asset_store"
import "components"
import "core:log"
import ECS "ecs"
import "systems"
import SDL "vendor:sdl3"

GameState :: struct {
	debug:         bool,
	is_running:    bool,
	ms_prev_frame: u64,
	asset_store:   ^store.AssetStore,
	window:        ^SDL.Window,
	renderer:      ^SDL.Renderer,
	registry:      ^ECS.Registry,
	memory:        ^Memory,
}


initialize :: proc(title: cstring, window_width: i32, window_height: i32) -> ^GameState {
	assert(SDL.Init(SDL.INIT_VIDEO), string(SDL.GetError()))
	window := SDL.CreateWindow(title, window_width, window_height, SDL.WINDOW_BORDERLESS)
	assert(window != nil, string(SDL.GetError()))
	renderer := SDL.CreateRenderer(window, nil)
	assert(renderer != nil, string(SDL.GetError()))

	gamestate := new(GameState)
	memory := new(Memory)
	memory_init(memory)

	asset_store := new(store.AssetStore)
	perm := memory_allocator(memory, ArenaKind.Permanent)
	store.init(asset_store, perm)

	level := memory_allocator(memory, ArenaKind.Level)
	registry := new(ECS.Registry)
	ECS.registry_init(registry, MAX_COMPONENTS, level)

	temp := memory_allocator(memory, ArenaKind.Frame)
	context.temp_allocator = temp

	gamestate^ = {
		debug       = false,
		is_running  = true,
		asset_store = asset_store,
		window      = window,
		renderer    = renderer,
		registry    = registry,
		memory      = memory,
	}

	return gamestate
}

destroy :: proc(gamestate: ^GameState) {
	log.info("destructor called")
	if gamestate.renderer != nil {
		SDL.DestroyRenderer(gamestate.renderer)
	}
	if gamestate.window != nil {
		SDL.DestroyWindow(gamestate.window)
	}
	memory_destroy(gamestate.memory)
	free(gamestate)
	SDL.Quit()
}

run :: proc(game: ^GameState) {
	setup(game)
	for (game.is_running) {
		ms_now := SDL.GetTicks()
		dt := f64(ms_now - game.ms_prev_frame) / 1000.0

		handle_events(game)
		update(game, dt)
		render(game)

		memory_reset_frame(game.memory)

		// waiting to match the frametime
		time_elapsed := ms_now - game.ms_prev_frame
		ms_wait := MS_PER_FRAME - time_elapsed
		if (ms_wait > 0 && ms_wait <= MS_PER_FRAME) {
			SDL.Delay(u32(ms_wait))
		}
		game.ms_prev_frame = ms_now
	}
}

setup :: proc(game: ^GameState) {
	game.ms_prev_frame = SDL.GetTicks()
	store.add_texture(game.asset_store, game.renderer, "player", "./assets/player.png")

	systems.render_system_register(game.registry)

	player := ECS.registry_create_entity(game.registry)
	player_sprite := components.SpriteComponent {
		asset_id = "player",
		width = 64.0,
		height = 96.0,
		z_index = 0,
		is_fixed = false,
		src_rect = SDL.FRect{x = 0, y = 0, w = 64.0, h = 96.0},
	}
	ECS.registry_add_component(game.registry, player.id, player_sprite)
	player_transform := components.TransformComponent {
		scale    = {2.0, 2.0},
		position = {0.0, 0.0},
		rotation = 0.0,
	}
	ECS.registry_add_component(game.registry, player.id, player_transform)
}

handle_events :: proc(game: ^GameState) {
	event: SDL.Event
	for SDL.PollEvent(&event) {
		#partial switch event.type {
		case .QUIT:
			game.is_running = false
		case .KEY_DOWN:
			if event.key.key == SDL.K_ESCAPE {
				game.is_running = false
			}
		case .WINDOW_RESIZED:
			log.infof("window resized [%d, %d]", event.window.data1, event.window.data2)
		case .WINDOW_FOCUS_GAINED:
			log.info("focus gained")
		case .WINDOW_EXPOSED:
			log.info("window exposed")
		}
	}
}

update :: proc(game: ^GameState, dt: f64) {
	ECS.registry_update(game.registry)
}

render :: proc(game: ^GameState) {
	SDL.SetRenderDrawColor(game.renderer, 0, 0, 0, 255)
	SDL.RenderClear(game.renderer)

	systems.render_system_update(game.registry, game.renderer, game.asset_store)

	SDL.RenderPresent(game.renderer)
}

