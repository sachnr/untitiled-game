package events

import "../ecs"
import "core:log"
import "core:mem"

EventBus :: struct {
	alloc:       mem.Allocator,
	input:       InputState,
	subscribers: [dynamic]Subscriber,
}

EventCallback :: proc(r: ^ecs.Registry, event: Event)

Subscriber :: struct {
	event_type: EventType,
	callback:   EventCallback,
}

event_bus_init :: proc(alloc: mem.Allocator) -> EventBus {
	log.info("initializing event bus")
	b: EventBus
	b.subscribers = make([dynamic]Subscriber, alloc)
	b.input = {}
	return b
}

event_bus_reset :: proc(bus: ^EventBus) {
	bus.input.pressed = {}
	bus.input.released = {}
	mem.free_all(bus.alloc)
}

event_bus_subscribe :: proc(bus: ^EventBus, event_type: EventType, callback: EventCallback) {
	append(&bus.subscribers, Subscriber{event_type, callback})
}

event_bus_emit :: proc(r: ^ecs.Registry, bus: ^EventBus, event: Event) {
	for sub in bus.subscribers {
		if sub.event_type == event.event_type {
			sub.callback(r, event)
		}
	}
}

