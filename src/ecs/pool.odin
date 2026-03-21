package ecs


import "core:mem"

@(private)
Pool :: struct($T: typeid) {
	data:            [dynamic]T,
	index_to_entity: [dynamic]u32,
	entity_to_index: map[u32]u32,
}

@(private)
pool_init :: proc(p: ^Pool($T), alloc: mem.Allocator) {
	p.data = make([dynamic]T, alloc)
	p.index_to_entity = make([dynamic]u32, alloc)
	p.entity_to_index = make_map(map[u32]u32, alloc)
}

@(private)
pool_clear :: proc(p: ^Pool($T)) {
	clear(&p.data)
	clear(&p.index_to_entity)
	clear(&p.entity_to_index)
}

@(private)
pool_set_entity :: proc(p: ^Pool($T), entity_id: u32, value: T) {
	idx, ok := p.entity_to_index[entity_id]
	if ok {
		// data already exists, overwriting existing component there.
		p.data[idx] = value
		return
	}

	idx = u32(len(p.data))
	append(&p.data, value)
	append(&p.index_to_entity, entity_id)
	p.entity_to_index[entity_id] = idx
}

@(private)
pool_remove_entity :: proc(p: ^Pool($T), entity_id: u32) {
	idx, ok := p.entity_to_index[entity_id]
	assert(ok, "pool_remove: entity should exist in the pool")

	assert(len(p.data) > 0, "pool_remove called on a empty pool")
	last_idx := u32(len(p.data) - 1)

	if idx != last_idx {
		last_entity_id := p.index_to_entity[last_idx]

		// move last → idx
		p.data[idx] = p.data[last_idx]
		p.index_to_entity[idx] = last_entity_id
		p.entity_to_index[last_entity_id] = idx
	}

	pop(&p.data)
	pop(&p.index_to_entity)
	delete_key(&p.entity_to_index, entity_id)
}

@(private)
pool_get_data :: proc(p: ^Pool($T), entity_id: u32) -> ^T {
	idx, ok := p.entity_to_index[entity_id]
	assert(ok, "pool_get_data: entity should exist in the pool")

	return &p.data[idx]
}

