package systems

import "../components/"
import "../ecs/"
import "core:log"

sprite_flip_system_register :: proc(r: ^ecs.Registry) {
	log.info("registering sprite flip system")

	signature: ecs.Signature = 0
	ecs.registry_signature_add_type(r, &signature, components.SpriteComponent)
	ecs.registry_signature_add_type(r, &signature, components.FacingComponent)
	ecs.registry_add_system(r, u32(Systems.SpriteFlipSystem), signature)
}

sprite_flip_system_update :: proc(r: ^ecs.Registry) {
	system := ecs.registry_get_system(r, u32(Systems.SpriteFlipSystem))
	assert(system != nil, "sprite flip system not registered")

	for entity in system.entities {
		facing := ecs.registry_get_component(r, entity, components.FacingComponent)
		sprite := ecs.registry_get_component(r, entity, components.SpriteComponent)

		log.info("direction: ", facing.direction)

		switch facing.direction {
		case .Left:
			sprite.is_flipped = true
		case .Right:
			sprite.is_flipped = false
		}
	}
}
