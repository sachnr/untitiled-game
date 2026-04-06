package main

import "core:log"

import "game"

main :: proc() {
	logger := log.create_console_logger()
	context.logger = logger

	gamestate: game.GameState
	game.initialize(&gamestate, "brawl", 800, 600)
	defer game.destroy(&gamestate)

	log.info("starting game")
	game.run(&gamestate)
}

