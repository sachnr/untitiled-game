package main

import "core:log"

FRAMES_PER_SECOND: u64 : 60
MS_PER_FRAME: u64 : 1000 / FRAMES_PER_SECOND
MAX_COMPONENTS: u8 : 32

main :: proc() {
	logger := log.create_console_logger()
	context.logger = logger

	gamestate := initialize("brawl", 800, 600)
	defer destroy(gamestate)
	run(gamestate)
}

