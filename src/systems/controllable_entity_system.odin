package systems

import components "../components/"
import core "../core"
import ecs "../ecs"
import events "../events/"
import "core:log"

controllable_entity_system_register :: proc(r: ^ecs.Registry) {
	log.info("registering controllable entity system")
	signature: ecs.Signature = 0
	ecs.registry_signature_add_type(r, &signature, components.RigidBodyComponent)
	ecs.registry_signature_add_type(r, &signature, components.ControllableEntityComponent)
	ecs.registry_signature_add_type(r, &signature, components.FacingComponent)
	ecs.registry_add_system(r, u32(Systems.ControllableEntitySystem), signature)
}

controllable_entity_handle_events :: proc(r: ^ecs.Registry, bus: ^events.EventBus) {
	system := ecs.registry_get_system(r, u32(Systems.ControllableEntitySystem))
	assert(system != nil, "controllable entity system not registered")

	for entity in system.entities {
		rigid_body := ecs.registry_get_component(r, entity, components.RigidBodyComponent)
		input := ecs.registry_get_component(r, entity, components.ControllableEntityComponent)
		facing := ecs.registry_get_component(r, entity, components.FacingComponent)

		dir: core.Vec2

		if .MoveUp in bus.input.held do dir.y -= 1
		if .MoveDown in bus.input.held do dir.y += 1
		if .MoveRight in bus.input.held do dir.x += 1
		if .MoveLeft in bus.input.held do dir.x -= 1

		if dir.x != 0 && dir.y != 0 do dir *= 0.7071

		if dir.x > 0 {
			facing.direction = .Right
		} else if dir.x < 0 {
			facing.direction = .Left
		}

		rigid_body.velocity = dir * input.speed
	}
}

