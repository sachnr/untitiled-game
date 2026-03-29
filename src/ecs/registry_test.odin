package ecs

import "core:mem/virtual"
import "core:testing"

TEST_MAX_COMPONENTS :: 32

Vec2 :: [2]f32

TestTransformComponent :: struct {
	position: Vec2,
}

TestSystems :: enum {
	TransformSystem,
}

register_transform_system :: proc(r: ^Registry) {
	sig: Signature = 0
	registry_signature_add_type(r, &sig, TestTransformComponent)
	registry_add_system(r, u32(TestSystems.TransformSystem), sig)
}

create_transformable_entity :: proc(r: ^Registry) -> Entity {
	e := registry_create_entity(r)
	transform_component := TestTransformComponent {
		position = {10, 20},
	}
	registry_add_component(r, e.id, transform_component)
	return e
}


@(test)
test_registry_adds_matching_entity_to_system :: proc(t: ^testing.T) {
	arena: virtual.Arena
	err := virtual.arena_init_growing(&arena)
	assert(err == nil, "failed to initialize test arena")
	defer virtual.arena_destroy(&arena)

	r := registry_init(TEST_MAX_COMPONENTS, virtual.arena_allocator(&arena))
	register_transform_system(&r)
	entity := create_transformable_entity(&r)

	registry_update(&r)

	system := registry_get_system(&r, u32(TestSystems.TransformSystem))
	testing.expect(t, system != nil)
	testing.expect(t, len(system.entities) == 1)
	testing.expect(t, system.entities[0].id == entity.id)

	comp := registry_get_component(&r, entity.id, TestTransformComponent)
	testing.expect(t, comp.position.x == 10)
	testing.expect(t, comp.position.y == 20)
}

