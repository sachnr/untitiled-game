package ecs

Signature :: u32

@(private)
signature_set :: proc(sig: ^Signature, component_id: u32) {
	sig^ |= Signature(1) << component_id
}

@(private)
signature_clear :: proc(sig: ^Signature, component_id: u32) {
	sig^ &= ~(Signature(1) << component_id)
}

@(private)
signature_has :: proc(sig: Signature, component_id: u32) -> bool {
	return (sig & (Signature(1) << component_id)) != 0
}

@(private)
signature_matches :: proc(entity_sig, system_sig: Signature) -> bool {
	return (entity_sig & system_sig) == system_sig
}

@(private)
signature_clear_all :: proc(sig: ^Signature) {
	sig^ = 0
}

