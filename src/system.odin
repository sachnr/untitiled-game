package main

System :: struct {
	component_signature: u64,
	entities:            [dynamic]Entity,
}

system_add_entity :: proc(system: ^System, entity: Entity) {
	append(&system.entities, entity)
}

system_remove_entity :: proc(system: ^System, entity: Entity) {
	found_id := -1
	for i in 0 ..< len(system.entities) {
		if system.entities[i].id == entity.id && system.entities[i].state == entity.state {
			found_id = i
		}
	}

	if found_id != -1 {
		ordered_remove(&system.entities, found_id)
	}
}

