package systems

import components "../components/"
import core "../core"
import ecs "../ecs"
import "../events/"
import "core:log"

player_state_system_register :: proc(r: ^ecs.Registry) {
	log.info("registering player state system")

	signature: ecs.Signature = 0
	ecs.registry_signature_add_type(r, &signature, components.RigidBodyComponent)
	ecs.registry_signature_add_type(r, &signature, components.PlayerStateComponent)
	ecs.registry_add_system(r, u32(Systems.PlayerStateSystem), signature)
}

player_state_system_update :: proc(r: ^ecs.Registry, bus: ^events.EventBus) {
	system := ecs.registry_get_system(r, u32(Systems.PlayerStateSystem))
	assert(system != nil, "player state system not registered")

	for entity in system.entities {
		rigid_body := ecs.registry_get_component(r, entity, components.RigidBodyComponent)
		state := ecs.registry_get_component(r, entity, components.PlayerStateComponent)

		is_moving := rigid_body.velocity.x != 0 || rigid_body.velocity.y != 0
		wanted_state: components.PlayerState = is_moving ? .Running : .Idle

		if wanted_state != state.state {
			old_state := state.state
			state.state = wanted_state
			update_player_state_data(state)
			state.curr_frame = 0

			event := events.Event {
				event_type = .PlayerStateChange,
				data = events.PlayerStateChangeData {
					entity = entity,
					state = state.state,
					anim = state.data,
				},
			}

			events.event_bus_emit(r, bus, event)
		}
	}
}

update_player_state_data :: proc(state: ^components.PlayerStateComponent) {
	switch state.state {
	case .Idle:
		state.data.is_loop = true
		state.data.row = 0
		state.data.frame_rate = 10.0
		state.data.frames = 10
	case .Running:
		state.data.is_loop = true
		state.data.row = 1
		state.data.frame_rate = 10.0
		state.data.frames = 8
	}
}

