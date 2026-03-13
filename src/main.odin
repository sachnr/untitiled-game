package main

import "core:log"

main :: proc() {
	logger := log.create_console_logger()
	context.logger = logger

	gamestate := initialize("pixel plane", 800, 600)
	defer destroy(gamestate)
	run(gamestate)
}

