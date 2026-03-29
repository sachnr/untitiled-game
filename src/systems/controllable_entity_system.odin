package systems

import components "../components/"
import core "../core"
import ecs "../ecs"
import events "../events/"
import "core:log"

controllable_entity_system_register :: proc(r: ^ecs.Registry) {
	log.info("registering controllable entity system")
	player_movement_signature: ecs.Signature = 0
	ecs.registry_signature_add_type(r, &player_movement_signature, components.RigidBodyComponent)
	ecs.registry_signature_add_type(
		r,
		&player_movement_signature,
		components.ControllableEntityComponent,
	)
	ecs.registry_add_system(r, u32(Systems.ControllableEntitySystem), player_movement_signature)
}

controllable_entity_handle_events :: proc(r: ^ecs.Registry, fc: ^events.FrameContext) {
	system := ecs.registry_get_system(r, u32(Systems.ControllableEntitySystem))
	assert(system != nil, "controllable entity system not registered")
	for entity in system.entities {
		rigid_body := ecs.registry_get_component(r, entity.id, components.RigidBodyComponent)
		cntrl_en := ecs.registry_get_component(
			r,
			entity.id,
			components.ControllableEntityComponent,
		)

		dir: core.Vec2

		if .MoveRight in fc.input_event.held do dir += cntrl_en.velocity_right
		if .MoveLeft in fc.input_event.held do dir += cntrl_en.velocity_left
		if .MoveForward in fc.input_event.held do dir += cntrl_en.velocity_up
		if .MoveBackward in fc.input_event.held do dir += cntrl_en.velocity_down

		if dir.x != 0 && dir.y != 0 do dir *= 0.7071

		rigid_body.velocity = dir
	}
}

