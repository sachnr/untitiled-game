package ecs

System_ID :: distinct u32

System :: struct {
	id:              System_ID,
	signature:       Signature,
	entities:        [dynamic]Entity,
	entity_to_index: map[u32]int,
}

@(private)
system_add_entity :: proc(s: ^System, entity: Entity) {
	if _, exists := s.entity_to_index[entity.id]; exists {
		return
	}

	idx := len(s.entities)
	append(&s.entities, entity)
	s.entity_to_index[entity.id] = idx
}

@(private)
system_remove_entity :: proc(s: ^System, entity: Entity) {
	idx, ok := s.entity_to_index[entity.id]
	assert(ok, "system_entity_remove: entity should exist in the system")

	last_idx := len(s.entities) - 1

	if idx != last_idx {
		last_entity := s.entities[last_idx]
		s.entities[idx] = last_entity
		s.entity_to_index[last_entity.id] = idx
	}

	pop(&s.entities)
	delete_key(&s.entity_to_index, entity.id)
}

