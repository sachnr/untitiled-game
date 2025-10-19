package main

import "core:fmt"
import "core:log"
import sdl "vendor:sdl3"

main :: proc() {
	gamestate := initialize("pixel plane", 800, 600)
	defer destroy(gamestate)
	run(gamestate)
}

