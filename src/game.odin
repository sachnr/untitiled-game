package main

import "core:fmt"
import "core:log"
import SDL "vendor:sdl3"
import TTF "vendor:sdl3/ttf"

GameState :: struct {
	debug:       bool,
	is_running:  bool,
	asset_store: ^AssetStore,
	window:      ^SDL.Window,
	renderer:    ^SDL.Renderer,
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
		window      = window,
		renderer    = renderer,
		asset_store = asset_store,
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
		handle_events(game)
		update(game)
		render(game)
	}
}

setup :: proc(game: ^GameState) {
	store_add_texture(game.asset_store, game.renderer, "truck", "./assets/truck.png")
}

handle_events :: proc(game: ^GameState) {
	event: SDL.Event
	for SDL.PollEvent(&event) {
		#partial switch event.type {
		case .QUIT:
			game.is_running = false
		case .WINDOW_RESIZED:
			log.infof("window resized [%d, %d]", event.window.data1, event.window.data2)
		case .WINDOW_FOCUS_GAINED:
			log.info("focus gained")
		case .WINDOW_EXPOSED:
			log.info("window exposed")
		}
	}
}

update :: proc(game: ^GameState) {
}

render :: proc(game: ^GameState) {
	SDL.SetRenderDrawColor(game.renderer, 0, 0, 0, 255)
	SDL.RenderClear(game.renderer)
	truck := store_get_texture(game.asset_store, "truck")
	src_rect := SDL.FRect {
		x = 0,
		y = 0,
		w = f32(truck.w),
		h = f32(truck.h),
	}
	dstrect := SDL.FRect {
		x = 0,
		y = 0,
		w = f32(truck.w),
		h = f32(truck.h),
	}
	SDL.RenderTexture(game.renderer, truck, &src_rect, &dstrect)

	SDL.RenderPresent(game.renderer)
}

