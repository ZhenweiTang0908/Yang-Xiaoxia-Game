extends "res://scripts/animation/actor_pose_art.gd"
# Same painted texture / 2D mesh as other bosses. No actor movement or combat writes.
# move: {bank: String, poses: [zero-based index, ...], times: [start seconds, ...]}.
# Alternatively poses: [{time: seconds, index: int, snap: bool}, ...].
# Absolute move time is actor.t; hold last pose. No inferred combat timing.
const ROOT = "res://assets/art/lion_elder_frames/"
var banks = {}
var active_bank = ""
var asset_status = "INCOMPLETE"
var last_error = ""
var raw_fallback_banks = {}
func resource_exists_for(path):return ResourceLoader.exists(path)

func setup(owner_actor) -> void:
	actor = owner_actor
	set_process(false) # Parent calls sync_pose exactly once; hitstop/pause stays with parent.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	banks.clear()
	active_bank = ""
	current = -1
	var names=["lion", "backfall", "sweep"]
	for folder in DirAccess.get_directories_at(ROOT):
		if folder not in names and FileAccess.file_exists(ROOT+folder+"/frames.json"):names.append(folder)
	for bank in names:
		var path = ROOT + bank + "/frames.json"
		if not FileAccess.file_exists(path):
			last_error = "Missing lion manifest: " + path
			continue
		var info = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not info is Dictionary or not info.get("frames") is Array or info.frames.is_empty():
			last_error = "Invalid lion manifest: " + path
			continue
		var pictures = []
		var used_bounds = []
		var origins = []
		var valid = true
		for entry in info.frames:
			var image_path = ROOT + bank + "/" + entry.file
			var picture: Texture2D
			# Generated sheets change faster than the editor import step. In the
			# editor/CI read the current PNG; exported packs always use imports.
			if not OS.has_feature("template") and FileAccess.file_exists(image_path):
				# Absolute paths keep Godot from warning that an imported texture was
				# read as a raw image on every frame.
				var raw_image = Image.load_from_file(ProjectSettings.globalize_path(image_path))
				if raw_image != null and not raw_image.is_empty():
					picture = ImageTexture.create_from_image(raw_image)
					# The editor path hides a missing import; an exported pack cannot.
					if not resource_exists_for(image_path) and not raw_fallback_banks.has(bank):
						raw_fallback_banks[bank] = true
						print("LION_ART_RAW_FALLBACK bank=", bank, " unimported frame; run an import pass before exporting")
			if picture == null and ResourceLoader.exists(image_path):
				picture = load(image_path) as Texture2D
			if picture == null:
				valid = false
				break
			pictures.append(picture)
			var used = picture.get_image().get_used_rect()
			# prepare() subtracts used.end.y; extend to the explicit support baseline.
			used.size.y = int(entry.baseline) - used.position.y
			used_bounds.append(used)
			origins.append(float(entry.anchor))
		if valid:
			banks[bank] = {"info": info, "pictures": pictures, "bounds": used_bounds, "anchors": origins}
	# One scale for ALL poses within each sheet; never resize a crouch to standing height.
	if banks.has("lion"): pose("lion", 0, true)

func _process(_dt):
	pass

func pose(bank: String, index: int, snap: bool = false) -> bool:
	if not banks.has(bank) or index < 0 or index >= banks[bank].pictures.size():
		last_error = "Unavailable lion pose: %s/%d" % [bank, index]
		return false # Preserve previous display, never silently clamp to an unrelated pose.
	if active_bank != bank:
		active_bank = bank
		var data = banks[bank]
		isolated = data.pictures
		bounds = data.bounds
		anchors = data.anchors
		regions = []
		for picture in isolated: regions.append(Rect2(Vector2.ZERO, picture.get_size()))
		body_height = float(data.info.reference_height)
		scale_unit = body_height / maxf(1.0, float(bounds[int(data.info.get("reference_frame",0))].size.y))
		cache.clear()
		current = -1
		bridge_from = PackedVector2Array()
		displayed = PackedVector2Array()
	frame = index
	var source_dir=actor.move.get("source_dir",actor.facing)
	# All authored sheets face left; explicit pose calls also set the mirror.
	facing=-source_dir
	# Distinct silhouettes must be authored; no stretching a standing mesh into a roll.
	prepare(frame)
	bridge_left = 0.0
	if snap: lean = 0.0; sink = 0.0
	queue_redraw()
	return true

func sync_pose(dt: float) -> void:
	if not is_instance_valid(actor): return
	clock += maxf(0.0, dt)
	var move = actor.move
	var source_dir=move.get("source_dir",actor.facing) if move is Dictionary else actor.facing
	facing = -source_dir # Turns retain their source direction.
	if not move is Dictionary: return
	var sequence = move.get("poses", [])
	var times = move.get("times", [])
	if not sequence is Array or sequence.is_empty(): return
	var selected = -1
	var previous = -INF
	for i in sequence.size():
		var entry = sequence[i]
		var start: float
		if entry is Dictionary:
			if not entry.has("time") or not entry.has("index"): return
			start = float(entry.time)
		else:
			if times.size() != sequence.size(): return
			start = float(times[i])
		if not is_finite(start) or start < 0 or start < previous: return
		previous = start
		if float(actor.t) >= start: selected = i
	if selected < 0: return
	var entry = sequence[selected]
	var index = int(entry.index) if entry is Dictionary else int(entry)
	pose(str(move.get("bank", "lion")), index, bool(entry.get("snap", false)) if entry is Dictionary else false)

func deform(p):
	# Keep support and rigid props authored, including hand/shoulder contact during rolls.
	return p

# The authored broad phase is only a cap. A contact also needs visible sprite
# pixels inside that cap, so an elbow cannot hit beyond its actual drawn reach.
func silhouette_intersects(world_rect: Rect2, root_position: Vector2) -> bool:
	if active_bank=="" or not world_rect.has_area():return false
	var data=banks[active_bank]
	if not data.has("images"):
		data.images=[]
		for picture in data.pictures:data.images.append(picture.get_image())
	var image: Image=data.images[frame]
	var local=world_rect.position-root_position
	var x0=local.x/facing/scale_unit+anchors[frame]
	var x1=(local.x+world_rect.size.x)/facing/scale_unit+anchors[frame]
	var y0=local.y/scale_unit+bounds[frame].end.y
	var y1=(local.y+world_rect.size.y)/scale_unit+bounds[frame].end.y
	var left=maxi(0,int(floor(minf(x0,x1))));var right=mini(image.get_width(),int(ceil(maxf(x0,x1))))
	var top=maxi(0,int(floor(y0)));var bottom=mini(image.get_height(),int(ceil(y1)))
	var step=maxi(1,int(1.0/scale_unit))
	for y in range(top,bottom,step):
		for x in range(left,right,step):
			if image.get_pixel(x,y).a>.35:return true
	return false

# Actual arrow shafts in the mouth explain why the next shot gets through.
# Keep this on the stable head pose; moving attack heads use their authored art.
func _draw():
	super._draw()
	if not is_instance_valid(actor) or actor.dead or actor.phase!=1 or actor.caught<=0:return
	if actor.action not in ["","spit"] or actor.phase_shift>0:return
	draw_set_transform(Vector2.ZERO)
	for index in mini(actor.caught,3):
		var mouth=Vector2(actor.facing*30,-67+index*4)
		var tail=mouth+Vector2(actor.facing*27,-3+index*2)
		draw_line(mouth,tail,Color("e5bf80"),2)
		draw_line(tail,tail+Vector2(-actor.facing*5,-3),Color("eee1bf"),2)
		draw_line(tail,tail+Vector2(-actor.facing*5,3),Color("eee1bf"),2)
