extends RefCounted
const CATALOG=preload("res://scripts/core/enemy_audio_catalog.gd")
const KNIGHT=preload("res://scripts/core/knight_audio_catalog.gd")
const RESET=preload("res://scripts/core/reset_audio_catalog.gd")
static func profiles():return CATALOG.PROFILES.merged(KNIGHT.PROFILES).merged(RESET.PROFILES)
const MOB_MOVES={"imp":"sweep","spirit":"orb","guardian":"sweep","pouncer":"pounce","bat":"pounce","dart":"dart","shield":"sweep","shaman":"rune"}
static func for_actor(actor):
	if not is_instance_valid(actor) or not actor is Node:return ""
	var kind=actor.get("kind")
	if kind=="boss":
		var identity=actor.spec.id+":"+str(actor.move.get("id",""))
		return identity if CATALOG.PROFILES.has(identity) or KNIGHT.PROFILES.has(identity) else ""
	return str(kind)+":"+MOB_MOVES[kind] if MOB_MOVES.has(kind) else ""
static func for_owner(owner):
	return for_actor(instance_from_id(owner)) if owner!=0 else ""
