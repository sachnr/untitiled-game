package game

import store "../asset_store"
import config "../config"
import "../core"
import ECS "../ecs"
import "../events"
import "../systems"
import "core:log"
import SDL "vendor:sdl3"

FRAMES_PER_SECOND: u64 : 60
MS_PER_FRAME: u64 : 1000 / FRAMES_PER_SECOND
MAX_COMPONENTS: u8 : 32

GameState :: struct {
	window:        ^SDL.Window,
	renderer:      ^SDL.Renderer,
	ms_prev_frame: u64,
	registry:      ECS.Registry,
	asset_store:   store.AssetStore,
	memory:        core.Memory,
	event_bus:     events.EventBus,
	debug:         bool,
	is_running:    bool,
}

initialize :: proc(gamestate: ^GameState, title: cstring, window_width: i32, window_height: i32) {
	assert(SDL.Init(SDL.INIT_VIDEO), string(SDL.GetError()))
	window := SDL.CreateWindow(title, window_width, window_height, SDL.WINDOW_BORDERLESS)
	assert(window != nil, string(SDL.GetError()))
	renderer := SDL.CreateRenderer(window, nil)
	assert(renderer != nil, string(SDL.GetError()))
	assert(
		SDL.SetRenderLogicalPresentation(
			renderer,
			window_width,
			window_height,
			SDL.RendererLogicalPresentation.LETTERBOX,
		),
		string(SDL.GetError()),
	)

	gamestate.debug = false
	gamestate.is_running = true
	gamestate.window = window
	gamestate.renderer = renderer

	gamestate.memory = core.memory_init()

	perm := core.memory_allocator(&gamestate.memory, core.ArenaKind.Permanent)
	gamestate.asset_store = store.init(perm)

	level := core.memory_allocator(&gamestate.memory, core.ArenaKind.Level)
	gamestate.registry = ECS.registry_init(MAX_COMPONENTS, level)

	frame := core.memory_allocator(&gamestate.memory, core.ArenaKind.Frame)
	gamestate.event_bus = events.event_bus_init(frame)

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
	core.memory_destroy(&gamestate.memory)
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

		events.event_bus_reset(&game.event_bus)

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
	systems.animation_system_register(&game.registry)
	systems.player_state_system_register(&game.registry)
	systems.sprite_flip_system_register(&game.registry)

	create_player(game)
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
			events.event_bus_set_action(&game.event_bus, action, true)
		case .KEY_UP:
			action := config.get_input_action(event.key.scancode)
			events.event_bus_set_action(&game.event_bus, action, false)
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
	systems.controllable_entity_handle_events(&game.registry, &game.event_bus)
	events.event_bus_subscribe(
		&game.event_bus,
		.PlayerStateChange,
		systems.animation_event_callback,
	)

	ECS.registry_update(&game.registry)

	systems.movement_system_update(&game.registry, dt)
	systems.player_state_system_update(&game.registry, &game.event_bus)
	systems.sprite_flip_system_update(&game.registry)
	systems.animation_system_update(&game.registry)
}

render :: proc(game: ^GameState) {
	SDL.SetRenderDrawColor(game.renderer, 0, 0, 0, 255)
	SDL.RenderClear(game.renderer)

	systems.render_system_update(
		&game.registry,
		game.renderer,
		&game.asset_store,
		core.memory_allocator(&game.memory, core.ArenaKind.Frame),
	)

	SDL.RenderPresent(game.renderer)
}

