extends SceneTree
var checks = 0
var failures = []
class MockActor extends Node2D:
	var facing = -1
	var t = 0.0
	var move = {}
func verify(ok: bool, message: String):
	checks += 1
	if not ok: failures.append(message); print("FAIL ", message)
func _initialize(): call_deferred("run")
func run():
	var script = load("res://scripts/animation/lion_elder_visual.gd")
	verify(script != null, "renderer loads")
	if script == null: finish(); return
	for bank in ["lion", "backfall", "sweep"]:
		var folder = "res://assets/art/lion_elder_frames/" + bank
		var info = JSON.parse_string(FileAccess.get_file_as_string(folder + "/frames.json"))
		verify(info is Dictionary, bank + " manifest exists")
		if not info is Dictionary: finish(); return
		verify(info.status == "INCOMPLETE" and info.approved_production_count == 0, "honest asset status")
		verify(info.frames.size() == 16 and not info.warnings.is_empty(), "study counts and warning")
		for entry in info.frames:
			var image = Image.load_from_file(folder + "/" + entry.file)
			verify(image != null and not image.is_empty(), "frame file exists")
			if image == null or image.is_empty(): finish(); return
			var used = image.get_used_rect()
			verify(used.has_area() and used.size.x < image.get_width() and used.size.y < image.get_height(), "background removed, silhouette retained")
			verify(entry.anchor >= used.position.x and entry.anchor < used.end.x and entry.baseline == used.end.y, "contact estimate lies within support bounds")
	var actor = MockActor.new()
	root.add_child(actor)
	var visual = script.new()
	actor.add_child(visual)
	visual.setup(actor)
	verify(visual.banks.size() >= 3, "all banks loaded")
	if visual.banks.size() < 3: actor.free(); finish(); return
	for bank in visual.banks:
		for i in visual.banks[bank].pictures.size():
			verify(visual.pose(bank, i, true), "select authored cell")
			visual.update_pose_mesh()
			var anchor = visual.anchors[i]
			var baseline = visual.bounds[i].end.y
			verify(visual.source_socket(i, Vector2(anchor, baseline)).length() < 0.001, "support maps exactly to actor origin")
	var prior = visual.frame
	verify(not visual.pose("missing", 0) and not visual.pose("lion", 16) and visual.frame == prior, "invalid request preserves display")
	actor.move = {"bank": "backfall", "poses": [0, 3, 7], "times": [0.0, 0.2, 0.4]}
	actor.t = 0.2
	visual.sync_pose(0.016)
	verify(visual.frame == 3 and visual.active_bank == "backfall" and visual.facing == 1, "time boundary and left-facing")
	actor.t = 20
	actor.facing = 1
	visual.sync_pose(0.016)
	verify(visual.frame == 7 and visual.facing == -1, "last pose held and mirrored")
	actor.move = {"bank": "sweep", "poses": [{"time": 0.0, "index": 5, "snap": true}]}
	visual.sync_pose(0.016)
	verify(visual.frame == 5 and visual.active_bank == "sweep" and visual.bridge_left == 0, "dictionary timeline snaps")
	actor.move = {"poses": [1, 2], "times": [0.5, 0.1]}
	visual.sync_pose(0.016)
	verify(visual.frame == 5, "invalid unsorted timeline preserves display")
	actor.free()
	finish()
func finish():
	print("LION_ART_RESULT checks=", checks, " failures=", failures.size(), " study=48 approved_production=0; no visual fluency assertion")
	quit(0 if failures.is_empty() else 1)
