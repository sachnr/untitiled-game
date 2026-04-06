package game

import components "../components"
import ECS "../ecs"
import SDL "vendor:sdl3"

create_player :: proc(game: ^GameState) {
	player := ECS.registry_create_entity(&game.registry)
	ECS.registry_tag_entity(&game.registry, player, "player")
	player_sprite := components.SpriteComponent {
		asset_id = "player",
		width = 64.0,
		height = 96.0,
		z_index = 0,
		is_fixed = false,
		src_rect = SDL.FRect{x = 0, y = 0, w = 64.0, h = 96.0},
	}
	ECS.registry_add_component(&game.registry, player, player_sprite)
	player_transform := components.TransformComponent {
		scale = {1.5, 1.5},
	}
	ECS.registry_add_component(&game.registry, player, player_transform)
	player_rigid_body := components.RigidBodyComponent{}
	ECS.registry_add_component(&game.registry, player, player_rigid_body)
	controllable_entity := components.ControllableEntityComponent {
		speed = 150,
	}
	ECS.registry_add_component(&game.registry, player, controllable_entity)
	animation_component := components.AnimationComponent {
		num_frames       = 10,
		current_frame    = 1,
		frame_rate_speed = 10.0,
		is_loop          = true,
		row              = 0,
		start_time       = SDL.GetTicks(),
	}
	ECS.registry_add_component(&game.registry, player, animation_component)
	ECS.registry_add_component(&game.registry, player, components.PlayerStateComponent{})
	ECS.registry_add_component(&game.registry, player, components.FacingComponent{})
}

