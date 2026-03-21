package ecs

@(private)
registry_get_or_create_component_id :: proc(r: ^Registry, $T: typeid) -> u32 {
	if id, ok := r.component_id_by_type[T]; ok {
		return id
	}

	id := len(r.component_pools)

	pool := new(Pool(T))
	pool_init(pool, r.alloc)

	append(&r.component_pools, pool)
	append(&r.component_type_ids, T)

	remove_fn := proc(ptr: rawptr, entity_id: u32) {
		p := cast(^Pool(T))ptr
		pool_remove_entity(p, entity_id)
	}

	append(&r.component_remove_fns, remove_fn)

	r.component_id_by_type[T] = u32(id)

	return u32(id)
}

@(private)
registry_get_component_id :: proc(r: ^Registry, $T: typeid) -> u32 {
	id, ok := r.component_id_by_type[T]
	assert(ok, "component type not registered in registry")
	return id
}

