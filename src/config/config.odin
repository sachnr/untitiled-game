package config

import SDL "vendor:sdl3"

Action :: enum u8 {
	Empty,
	MoveUp,
	MoveDown,
	MoveLeft,
	MoveRight,
	Jump,
}

DEFAULT_BINDINGS: [512]Action

init_bindings :: proc() {
	DEFAULT_BINDINGS[SDL.Scancode.W] = .MoveUp
	DEFAULT_BINDINGS[SDL.Scancode.S] = .MoveDown
	DEFAULT_BINDINGS[SDL.Scancode.A] = .MoveLeft
	DEFAULT_BINDINGS[SDL.Scancode.D] = .MoveRight
	DEFAULT_BINDINGS[SDL.Scancode.SPACE] = .Jump
}

get_input_action :: proc(code: SDL.Scancode) -> Action {
	action := DEFAULT_BINDINGS[code]
	if action == .Empty do return .Empty
	return action
}

