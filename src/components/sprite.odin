package components

import SDL "vendor:sdl3"

SpriteComponent :: struct {
	asset_id: string,
	width:    i32,
	height:   i32,
	z_index:  i32,
	is_fixed: bool,
	src_rect: SDL.FRect,
}

