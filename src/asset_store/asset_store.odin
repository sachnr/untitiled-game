package asset_store

import "core:fmt"
import "core:mem"
import SDL "vendor:sdl3"
import IMAGE "vendor:sdl3/image"
import TTF "vendor:sdl3/ttf"

AssetStore :: struct {
	textures: map[string]^SDL.Texture,
	fonts:    map[string]^TTF.Font,
}

init :: proc(a: ^AssetStore, arena: mem.Allocator) {
	a.textures = make_map(map[string]^SDL.Texture, arena)
	a.fonts = make_map(map[string]^TTF.Font, arena)
}

add_texture :: proc(
	asset_store: ^AssetStore,
	renderer: ^SDL.Renderer,
	asset_id: string,
	path: cstring,
) {
	surface := IMAGE.Load(path)
	assert(surface != nil, "file path not fount")
	texture := SDL.CreateTextureFromSurface(renderer, surface)
	SDL.free(surface)
	assert(texture != nil, string(SDL.GetError()))
	asset_store.textures[asset_id] = texture
}

get_texture :: proc(asset_store: ^AssetStore, asset_id: string) -> ^SDL.Texture {
	texture, ok := asset_store.textures[asset_id]
	assert(ok, fmt.tprintf("texture not found, id: %s", asset_id))
	return texture
}

