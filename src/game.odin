package main

import store "asset_store"
import "components"
import config "config"
import "core:log"
import ECS "ecs"
import "events"
import "systems"
import SDL "vendor:sdl3"

GameState :: struct {
	window:        ^SDL.Window,
	renderer:      ^SDL.Renderer,
	ms_prev_frame: u64,
	registry:      ECS.Registry,
	asset_store:   store.AssetStore,
	memory:        Memory,
	fc:            events.FrameContext,
	debug:         bool,
	is_running:    bool,
}


initialize :: proc(gamestate: ^GameState, title: cstring, window_width: i32, window_height: i32) {
	assert(SDL.Init(SDL.INIT_VIDEO), string(SDL.GetError()))
	window := SDL.CreateWindow(title, window_width, window_height, SDL.WINDOW_BORDERLESS)
	assert(window != nil, string(SDL.GetError()))
	renderer := SDL.CreateRenderer(window, nil)
	assert(renderer != nil, string(SDL.GetError()))

	gamestate.debug = false
	gamestate.is_running = true
	gamestate.window = window
	gamestate.renderer = renderer

	gamestate.memory = memory_init()

	perm := memory_allocator(&gamestate.memory, ArenaKind.Permanent)
	gamestate.asset_store = store.init(perm)

	level := memory_allocator(&gamestate.memory, ArenaKind.Level)
	gamestate.registry = ECS.registry_init(MAX_COMPONENTS, level)

	frame := memory_allocator(&gamestate.memory, ArenaKind.Frame)
	gamestate.fc = events.frame_context_init(frame)

	log.info("initializing default config")
	config.init_bindings()
}

destroy :: proc(gamestate: ^GameState) {
	log.info("destructor called")
	if gamestate.renderer != nil {
		SDL.DestroyRenderer(gamestate.renderer)
	}
	if gamestate.window != nil {
		SDL.DestroyWindow(gamestate.window)
	}
	memory_destroy(&gamestate.memory)
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

		events.frame_context_reset(&game.fc)

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
	store.add_texture(&game.asset_store, game.renderer, "player", "./assets/player.png")

	systems.render_system_register(&game.registry)
	systems.movement_system_register(&game.registry)
	systems.controllable_entity_system_register(&game.registry)

	player := ECS.registry_create_entity(&game.registry)
	player_sprite := components.SpriteComponent {
		asset_id = "player",
		width = 64.0,
		height = 96.0,
		z_index = 0,
		is_fixed = false,
		src_rect = SDL.FRect{x = 0, y = 0, w = 64.0, h = 96.0},
	}
	ECS.registry_add_component(&game.registry, player.id, player_sprite)
	player_transform := components.TransformComponent {
		scale = {1.5, 1.5},
	}
	ECS.registry_add_component(&game.registry, player.id, player_transform)
	player_rigid_body := components.RigidBodyComponent{}
	ECS.registry_add_component(&game.registry, player.id, player_rigid_body)
	controllable_entity := components.ControllableEntityComponent {
		velocity_up    = {0, -50},
		velocity_down  = {0, 50},
		velocity_left  = {-50, 0},
		velocity_right = {50, 0},
	}
	ECS.registry_add_component(&game.registry, player.id, controllable_entity)
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
			action := config.get_input_action(event.key.scancode)
			events.frame_context_set_action(&game.fc, action, true)
		case .KEY_UP:
			action := config.get_input_action(event.key.scancode)
			events.frame_context_set_action(&game.fc, action, false)
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
	systems.controllable_entity_handle_events(&game.registry, &game.fc)

	ECS.registry_update(&game.registry)

	systems.movement_system_update(&game.registry, dt)
}

render :: proc(game: ^GameState) {
	SDL.SetRenderDrawColor(game.renderer, 0, 0, 0, 255)
	SDL.RenderClear(game.renderer)

	systems.render_system_update(
		&game.registry,
		game.renderer,
		&game.asset_store,
		memory_allocator(&game.memory, ArenaKind.Frame),
	)

	SDL.RenderPresent(game.renderer)
}

