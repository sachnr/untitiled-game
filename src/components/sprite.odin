package components

import SDL "vendor:sdl3"

SpriteComponent :: struct {
	asset_id:   string,
	angle:      f64,
	width:      i32,
	height:     i32,
	z_index:    i32,
	is_fixed:   bool,
	is_flipped: bool,
	src_rect:   SDL.FRect,
}

