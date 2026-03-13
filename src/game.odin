package main

import "core:log"
import SDL "vendor:sdl3"
import TTF "vendor:sdl3/ttf"

GameState :: struct {
	debug:         bool,
	is_running:    bool,
	ms_prev_frame: u64,
	player:        Player,
	asset_store:   ^AssetStore,
	window:        ^SDL.Window,
	renderer:      ^SDL.Renderer,
}

Player :: struct {
	velocity: Vector2,
	position: Vector2,
	height:   f32,
	width:    f32,
}

Vector2 :: struct {
	x: f64,
	y: f64,
}

initialize :: proc(title: cstring, window_width: i32, window_height: i32) -> ^GameState {
	assert(SDL.Init(SDL.INIT_VIDEO), string(SDL.GetError()))
	window := SDL.CreateWindow(title, window_width, window_height, SDL.WINDOW_BORDERLESS)
	assert(window != nil, string(SDL.GetError()))
	renderer := SDL.CreateRenderer(window, nil)
	assert(renderer != nil, string(SDL.GetError()))

	gamestate := new(GameState)
	asset_store := new(AssetStore)
	asset_store^ = AssetStore {
		textures = make_map(map[string]^SDL.Texture),
		fonts    = make_map(map[string]^TTF.Font),
	}

	gamestate^ = {
		debug       = false,
		is_running  = true,
		player      = Player{},
		asset_store = asset_store,
		window      = window,
		renderer    = renderer,
	}

	return gamestate
}

destroy :: proc(gamestate: ^GameState) {
	if gamestate.window != nil {
		SDL.DestroyWindow(gamestate.window)
	}
	if gamestate.renderer != nil {
		SDL.DestroyRenderer(gamestate.renderer)
	}
	SDL.Quit()
	free(gamestate)
}

run :: proc(game: ^GameState) {
	setup(game)
	for (game.is_running) {
		ms_now := SDL.GetTicks()
		dt := f64(ms_now - game.ms_prev_frame) / 1000.0

		handle_events(game)
		update(game, dt)
		render(game)

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
	game.player.height = 96
	game.player.width = 64
	game.player.position = Vector2 {
		x = 0,
		y = 0,
	}
	game.player.velocity = Vector2 {
		x = 5,
		y = 0,
	}
	store_add_texture(game.asset_store, game.renderer, "player", "./assets/player.png")
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
	game.player.position.x += game.player.velocity.x * dt
	game.player.position.y += game.player.velocity.y * dt

	log.infof("player_pos: x:%f, y:%f", game.player.position.x, game.player.position.y)
}

render :: proc(game: ^GameState) {
	SDL.SetRenderDrawColor(game.renderer, 0, 0, 0, 255)
	SDL.RenderClear(game.renderer)

	player := store_get_texture(game.asset_store, "player")
	src_rect := SDL.FRect {
		x = 0,
		y = 0,
		w = f32(game.player.width),
		h = f32(game.player.height),
	}
	dstrect := SDL.FRect {
		x = f32(game.player.position.x),
		y = f32(game.player.position.y),
		w = f32(game.player.width),
		h = f32(game.player.height),
	}

	SDL.RenderTexture(game.renderer, player, &src_rect, &dstrect)
	SDL.RenderPresent(game.renderer)
}

