package main

Entity_State :: enum {
	Alive,
	Pending_Destroy,
}

Entity :: struct {
	id:    u32,
	state: Entity_State,
}

