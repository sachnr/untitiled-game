package ecs

import "core:container/queue"
import "core:log"
import "core:mem"

Entity :: struct {
	id: u32,
}

Registry :: struct {
	alloc:                       mem.Allocator,
	num_entities:                u32,
	max_components:              u8,
	entities:                    [dynamic]Entity,

	// Array of component signatures per entity,
	// saying which component is turned "on" for a given entity
	// [array index = entity id]
	entity_component_signatures: [dynamic]Signature,

	// Set of entities that are flagged to be added or removed
	// in the next registry Update()
	entities_to_add:             [dynamic]Entity,
	entities_to_remove:          [dynamic]Entity,

	// Array of component pools, each pool contains
	// all the data for a certain compoenent type
	component_pools:             [dynamic]rawptr,
	component_type_ids:          [dynamic]typeid,
	component_id_by_type:        map[typeid]u32,
	component_remove_fns:        [dynamic]proc(ptr: rawptr, entity_id: u32),

	// array of systems
	systems:                     [dynamic]System,

	// list of free entity ids
	free_ids:                    queue.Queue(u32),
}

registry_init :: proc(max_components: u8, alloc: mem.Allocator) -> Registry {
	log.info("Initializing new world registry")

	r: Registry

	r.alloc = alloc
	r.num_entities = 0
	r.max_components = max_components

	r.entities = make([dynamic]Entity, alloc)
	r.entity_component_signatures = make([dynamic]Signature, alloc)

	r.entities_to_add = make([dynamic]Entity, alloc)
	r.entities_to_remove = make([dynamic]Entity, alloc)

	r.component_pools = make([dynamic]rawptr, alloc)
	r.component_type_ids = make([dynamic]typeid, alloc)
	r.component_remove_fns = make([dynamic]proc(_: rawptr, _: u32), alloc)
	r.component_id_by_type = make_map(map[typeid]u32, alloc)

	r.systems = make([dynamic]System, alloc)

	err := queue.init(&r.free_ids, 128, alloc)
	assert(err == nil, "failed to initialize free_ids queue")

	return r
}

registry_create_entity :: proc(r: ^Registry) -> Entity {
	id: u32

	if r.free_ids.len > 0 {
		id = queue.pop_front(&r.free_ids)
	} else {
		id = r.num_entities
		r.num_entities += 1

		if int(id) >= len(r.entity_component_signatures) {
			resize(&r.entity_component_signatures, int(id) + 1)
		}
	}

	signature_clear_all(&r.entity_component_signatures[id])

	entity := Entity {
		id = id,
	}

	append(&r.entities_to_add, entity)
	log.infof("entity queued for creation: %d", entity.id)

	return entity
}

registry_kill_entity :: proc(r: ^Registry, entity: Entity) {
	append(&r.entities_to_remove, entity)
	log.infof("entity queued for deletion: %d", entity.id)
}

registry_signature_add_type :: proc(r: ^Registry, sig: ^Signature, $T: typeid) {
	id := registry_get_or_create_component_id(r, T)
	signature_set(sig, id)
}

registry_add_system :: proc(r: ^Registry, system_id: u32, sig: Signature) {
	s := System {
		id              = System_ID(system_id),
		entities        = make([dynamic]Entity, r.alloc),
		entity_to_index = make_map(map[u32]int, r.alloc),
		signature       = sig,
	}

	append(&r.systems, s)
	log.infof("system added to registry: (id: %d) (sig: %d)", s.id, s.signature)
}

registry_get_system :: proc(r: ^Registry, system_id: u32) -> ^System {
	sid := System_ID(system_id)

	for i in 0 ..< len(r.systems) {
		if r.systems[i].id == sid {
			return &r.systems[i]
		}
	}

	return nil
}

@(private)
registry_add_entity_to_systems :: proc(r: ^Registry, entity: Entity) {
	signature := r.entity_component_signatures[entity.id]

	for &system in r.systems {
		system_signature := system.signature
		ok := signature_matches(signature, system_signature)

		if ok {
			system_add_entity(&system, entity)
			log.infof("entity_id %d added to system_id %d", entity.id, system.id)
		}
	}
}

@(private)
registry_remove_entity_from_system :: proc(r: ^Registry, entity: Entity) {
	for &system in r.systems {
		if _, exists := system.entity_to_index[entity.id]; exists {
			system_remove_entity(&system, entity)
			log.infof("entity_id %d removed from system_id %d", entity.id, system.id)
		}
	}
}

@(private)
registry_get_pool :: proc(r: ^Registry, $T: typeid) -> ^Pool(T) {
	id, ok := r.component_id_by_type[T]
	assert(ok, "component not registered")

	return cast(^Pool(T))r.component_pools[id]
}

registry_add_component :: proc(r: ^Registry, entity_id: u32, component: $T) {
	cid := registry_get_or_create_component_id(r, T)
	assert(cid < u32(r.max_components), "component id exceeds Signature(u32) capacity")
	pool := registry_get_pool(r, T)
	pool_set_entity(pool, entity_id, component)
	signature_set(&r.entity_component_signatures[entity_id], cid)
	log.infof("component %d added for entity %d", cid, entity_id)
}

registry_get_component :: proc(r: ^Registry, entity_id: u32, $T: typeid) -> ^T {
	cid := registry_get_component_id(r, T)
	pool := registry_get_pool(r, T)
	entity := pool_get_data(pool, entity_id)
	return entity
}

registry_update :: proc(r: ^Registry) {
	for entity in r.entities_to_add {
		registry_add_entity_to_systems(r, entity)
		log.infof("entity %d added to the registry", entity.id)
	}
	clear(&r.entities_to_add)

	for entity in r.entities_to_remove {
		registry_remove_entity_from_system(r, entity)
		sig := r.entity_component_signatures[entity.id]
		for component_id in 0 ..< len(r.component_pools) {
			if signature_has(sig, u32(component_id)) {
				pool_ptr := r.component_pools[component_id]
				remove_fn := r.component_remove_fns[component_id]
				remove_fn(pool_ptr, entity.id)
			}
		}
		signature_clear_all(&r.entity_component_signatures[entity.id])
		queue.push_back(&r.free_ids, entity.id)
		log.infof("entity %d deleted from the registry", entity.id)
	}
	clear(&r.entities_to_remove)
}

