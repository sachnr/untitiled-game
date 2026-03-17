package main

import "core:mem"

Pool :: struct($T: typeid) {
	data:            [dynamic]T,
	index_to_entity: [dynamic]u32,
	entity_to_index: [dynamic]u32,
	size:            u64,
}

// pool_clear           :: proc(pool: ^Pool($T)) // clears logical contents
// pool_has             :: proc(pool: ^Pool($T), entity_id: u32) -> bool
// pool_get_ptr         :: proc(pool: ^Pool($T), entity_id: u32) -> ^T
// pool_set             :: proc(pool: ^Pool($T), entity_id: u32, value: T) // add-or-replace
// pool_remove          :: proc(pool: ^Pool($T), entity_id: u32) -> bool
// pool_ensure_entity   :: proc(pool: ^Pool($T), entity_id: u32) // grows entity_to_index

pool_init :: proc(pool: ^Pool($T), alloc: mem.Allocator) {
	pool.data = make([dynamic]T, 0, 0, alloc)
	pool.index_to_entity = make([dynamic]u32, 0, 0, alloc)
	pool.entity_to_index = make([dynamic]u32, 0, 0, alloc)
}

pool_clear :: proc(pool: ^Pool($T)) {
	clear(&pool.data)
	clear(&pool.index_to_entity)
	clear(&pool.entity_to_index)
}

