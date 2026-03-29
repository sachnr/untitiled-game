package systems

import components "../components/"
import ecs "../ecs"
import "core:log"
import SDL "vendor:sdl3"

animation_system_register :: proc(r: ^ecs.Registry) {
	log.info("registering animation system")

	render_signature: ecs.Signature = 0
	ecs.registry_signature_add_type(r, &render_signature, components.SpriteComponent)
	ecs.registry_signature_add_type(r, &render_signature, components.AnimationComponent)
	ecs.registry_add_system(r, u32(Systems.AnimationSystem), render_signature)
}

animation_system_update :: proc(r: ^ecs.Registry) {
	system := ecs.registry_get_system(r, u32(Systems.AnimationSystem))

	for entity in system.entities {
		animation := ecs.registry_get_component(r, entity.id, components.AnimationComponent)
		sprite := ecs.registry_get_component(r, entity.id, components.SpriteComponent)

		current_frame :=
			((SDL.GetTicks() - animation.start_time) * u64(animation.frame_rate_speed) / 1000) %
			u64(animation.num_frames)

		animation.current_frame = u8(current_frame)
		sprite.src_rect.x = f32(current_frame) * sprite.src_rect.w
	}
}

