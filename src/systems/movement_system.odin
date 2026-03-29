package systems

import components "../components/"
import ecs "../ecs"
import "core:log"

movement_system_register :: proc(r: ^ecs.Registry) {
	log.info("registering movement system")
	player_movement_signature: ecs.Signature = 0
	ecs.registry_signature_add_type(r, &player_movement_signature, components.RigidBodyComponent)
	ecs.registry_signature_add_type(r, &player_movement_signature, components.TransformComponent)
	ecs.registry_add_system(r, u32(Systems.MovementSystem), player_movement_signature)
}

movement_system_update :: proc(r: ^ecs.Registry, dt: f64) {
	system := ecs.registry_get_system(r, u32(Systems.MovementSystem))

	for entity in system.entities {
		rigid_body := ecs.registry_get_component(r, entity.id, components.RigidBodyComponent)
		transform := ecs.registry_get_component(r, entity.id, components.TransformComponent)

		transform.position.x += rigid_body.velocity.x * f32(dt)
		transform.position.y += rigid_body.velocity.y * f32(dt)
	}
}

