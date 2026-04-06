package events

import config "../config"

InputState :: struct {
	held:     bit_set[config.Action],
	pressed:  bit_set[config.Action],
	released: bit_set[config.Action],
}

event_bus_set_action :: proc(bus: ^EventBus, action: config.Action, is_down: bool) {
	if action == .Empty do return

	if is_down {
		bus.input.pressed += {action}
		bus.input.held += {action}
	} else {
		bus.input.released += {action}
		bus.input.held -= {action}
	}
}
