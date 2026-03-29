package components

AnimationComponent :: struct {
	start_time:       u64,
	num_frames:       u8,
	current_frame:    u8,
	frame_rate_speed: u8,
	is_loop:          bool,
}

