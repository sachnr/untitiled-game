package events

import config "../config"
import "core:mem"

import "core:log"

FrameContext :: struct {
	alloc:       mem.Allocator,
	input_event: InputState,
}

InputState :: struct {
	held:     bit_set[config.Action],
	pressed:  bit_set[config.Action],
	released: bit_set[config.Action],
}

frame_context_init :: proc(alloc: mem.Allocator) -> FrameContext {
	log.info("initializing frame context")
	return FrameContext{alloc = alloc, input_event = {}}
}

frame_context_reset :: proc(fc: ^FrameContext) {
	fc.input_event.pressed = {}
	fc.input_event.released = {}
	mem.free_all(fc.alloc)
}

frame_context_set_action :: proc(fc: ^FrameContext, action: config.Action, is_down: bool) {
	if action == .Empty do return

	if is_down {
		fc.input_event.pressed += {action}
		fc.input_event.held += {action}
	} else {
		fc.input_event.released += {action}
		fc.input_event.held -= {action}
	}
}

