package main

import mem "core:mem"
import vmem "core:mem/virtual"

ArenaKind :: enum {
	Permanent,
	Frame,
	Level,
}

Memory :: struct {
	permanent: vmem.Arena,
	level:     vmem.Arena,
	frame:     vmem.Arena,
}

memory_init :: proc(m: ^Memory) {
	err := vmem.arena_init_growing(&m.permanent)
	assert(err == nil, "Failed to allocate memory")

	err = vmem.arena_init_growing(&m.level)
	assert(err == nil, "Failed to allocate memory")

	err = vmem.arena_init_growing(&m.frame)
	assert(err == nil, "Failed to allocate memory")
}

memory_reset_frame :: proc(m: ^Memory) {
	vmem.arena_free_all(&m.frame)
}

memory_reset_level :: proc(m: ^Memory) {
	vmem.arena_free_all(&m.level)
}

memory_allocator :: proc(m: ^Memory, kind: ArenaKind) -> mem.Allocator {
	switch kind {
	case .Permanent:
		return vmem.arena_allocator(&m.permanent)
	case .Level:
		return vmem.arena_allocator(&m.level)
	case .Frame:
		return vmem.arena_allocator(&m.frame)
	}
	return {}
}

memory_destroy :: proc(m: ^Memory) {
	vmem.arena_destroy(&m.frame)
	vmem.arena_destroy(&m.level)
	vmem.arena_destroy(&m.permanent)
}

