package events

import "../components/"
import "../ecs"

Event :: struct {
	event_type: EventType,
	data:       union {
		PlayerStateChangeData,
	},
}

EventType :: enum {
	PlayerStateChange,
}

PlayerStateChangeData :: struct {
	entity: ecs.Entity,
	state:  components.PlayerState,
	anim:   components.PlayerStateData,
}

