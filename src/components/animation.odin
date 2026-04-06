package components

AnimationComponent :: struct {
	start_time:       u64,
	frame_rate_speed: f32,
	num_frames:       u8,
	current_frame:    u8,
	row:              u8,
	is_loop:          bool,
}

