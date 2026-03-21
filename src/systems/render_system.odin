package systems

import store "../asset_store/"
import components "../components/"
import ecs "../ecs"
import "core:sort"
import SDL "vendor:sdl3"

render_system_register :: proc(r: ^ecs.Registry) {
	render_signature: ecs.Signature = 0
	ecs.registry_signature_add_type(r, &render_signature, components.SpriteComponent)
	ecs.registry_signature_add_type(r, &render_signature, components.TransformComponent)
	ecs.registry_add_system(r, u32(Systems.RenderSystem), render_signature)
}


render_system_update :: proc(
	r: ^ecs.Registry,
	renderer: ^SDL.Renderer,
	asset_store: ^store.AssetStore,
) {
	system := ecs.registry_get_system(r, u32(Systems.RenderSystem))

	RenderableEntity :: struct {
		entity_id:           u32,
		sprite_component:    components.SpriteComponent,
		transform_component: components.TransformComponent,
	}

	entities := make([dynamic]RenderableEntity, context.temp_allocator)

	for entity in system.entities {
		sprite := ecs.registry_get_component(r, entity.id, components.SpriteComponent)^
		transform := ecs.registry_get_component(r, entity.id, components.TransformComponent)^
		append(
			&entities,
			RenderableEntity {
				entity_id = entity.id,
				sprite_component = sprite,
				transform_component = transform,
			},
		)
	}

	z_index_sort :: proc(a, b: RenderableEntity) -> int {
		if a.sprite_component.z_index < b.sprite_component.z_index do return -1
		if a.sprite_component.z_index > b.sprite_component.z_index do return +1
		if a.entity_id < b.entity_id do return -1
		if a.entity_id > b.entity_id do return +1
		return 0
	}

	sort.quick_sort_proc(entities[:], z_index_sort)

	for entity in entities {
		src_rect := entity.sprite_component.src_rect
		dst_rect := SDL.FRect {
			x = f32(entity.transform_component.position.x),
			y = f32(entity.transform_component.position.y),
			w = entity.transform_component.scale.x * f32(entity.sprite_component.width),
			h = entity.transform_component.scale.y * f32(entity.sprite_component.height),
		}

		sprite := store.get_texture(asset_store, entity.sprite_component.asset_id)

		SDL.RenderTexture(renderer, sprite, &src_rect, &dst_rect)
	}
}

