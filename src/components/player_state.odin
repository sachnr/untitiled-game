package components

PlayerStateComponent :: struct {
	curr_frame:    u64,
	state:         PlayerState,
	flags:         bit_set[PlayerFlags],
	data:          PlayerStateData,
	interruptable: bool,
}

PlayerFlags :: enum {
	IsGrounded,
}

PlayerState :: enum {
	Idle,
	Running,
}

PlayerStateData :: struct {
	frame_rate: f32,
	row:        u8,
	frames:     u8,
	is_loop:    bool,
}

