package asset_store

import "core:fmt"
import "core:log"
import "core:mem"
import SDL "vendor:sdl3"
import IMAGE "vendor:sdl3/image"
import TTF "vendor:sdl3/ttf"

AssetStore :: struct {
	textures: map[string]^SDL.Texture,
	fonts:    map[string]^TTF.Font,
}

init :: proc(arena: mem.Allocator) -> AssetStore {
	log.info("initializing asset store")

	a: AssetStore
	a.textures = make_map(map[string]^SDL.Texture, arena)
	a.fonts = make_map(map[string]^TTF.Font, arena)

	return a
}

add_texture :: proc(
	asset_store: ^AssetStore,
	renderer: ^SDL.Renderer,
	asset_id: string,
	path: cstring,
) {
	log.infof("add_texture: loading %s", path)
	surface := IMAGE.Load(path)
	assert(surface != nil, "file path not fount")
	texture := SDL.CreateTextureFromSurface(renderer, surface)
	SDL.free(surface)
	assert(texture != nil, string(SDL.GetError()))
	assert(SDL.SetTextureScaleMode(texture, SDL.ScaleMode.NEAREST), string(SDL.GetError()))
	asset_store.textures[asset_id] = texture
}

destroy_texture :: proc(a: ^AssetStore, asset_id: string) {
	tex, ok := a.textures[asset_id]
	if !ok do return

	SDL.DestroyTexture(tex)
	delete_key(&a.textures, asset_id)
}

get_texture :: proc(asset_store: ^AssetStore, asset_id: string) -> ^SDL.Texture {
	texture, ok := asset_store.textures[asset_id]
	assert(ok, fmt.tprintf("texture not found, id: %s", asset_id))
	return texture
}

