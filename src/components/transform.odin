package components

import "core:math/linalg"

TransformComponent :: struct {
	position: linalg.Vector2f32,
	scale:    linalg.Vector2f32,
	rotation: f32,
}

