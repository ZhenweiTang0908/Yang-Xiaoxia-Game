extends SceneTree
# Study extraction only. Source images remain untouched; no production approval implied.
const ROOT = "res://assets/art/lion_elder_frames/"
const SOURCES = {
	"lion": "poses-lion-lift-study-v1.png",
	"backfall": "poses-backfall-study-v1.png",
	"sweep": "poses-sweep-handstand-study-v1.png",
}
const WARNINGS = {
	"lion": "03→04 leg extension and 07→08 head rotation jump; 11/12 grips unclear; cloth too broad; lamp too detailed.",
	"backfall": "08→09 support transition abrupt; 10→11 torso/facing discontinuity; 15/16 near duplicate.",
	"sweep": "06→07 shoulder/hip turn missing; 10→11 airborne transition missing; gourd side drifts across boards.",
}
func _initialize():
	call_deferred("run")

# Only edge-connected blue-gray background is removed, preserving enclosed colors.
static func key_background(image: Image) -> void:
	var w = image.get_width()
	var h = image.get_height()
	var seen = PackedByteArray()
	seen.resize(w * h)
	var queue = PackedInt32Array()
	for x in w:
		queue.append(x)
		queue.append((h - 1) * w + x)
	for y in h:
		queue.append(y * w)
		queue.append(y * w + w - 1)
	var cursor = 0
	while cursor < queue.size():
		var cell = queue[cursor]
		cursor += 1
		if seen[cell]:
			continue
		seen[cell] = 1
		var x = cell % w
		var y = int(cell / w)
		var c = image.get_pixel(x, y)
		# Board backdrop is cool blue-gray; indigo clothing is less green.
		if c.a > 0.01 and not (c.b > c.r * 1.12 and c.g > c.r * 1.10 and c.g > c.b * 0.78 and c.b < 0.5):
			continue
		image.set_pixel(x, y, Color.TRANSPARENT)
		if x > 0: queue.append(cell - 1)
		if x + 1 < w: queue.append(cell + 1)
		if y > 0: queue.append(cell - w)
		if y + 1 < h: queue.append(cell + w)

# A regular grid can include the neighboring row's fringe. Keep only the
# principal silhouette's spatial envelope, including its enclosed loose details.
static func isolate_cell(image: Image) -> void:
	var w=image.get_width();var h=image.get_height()
	var visited=PackedByteArray();visited.resize(w*h)
	var largest=Rect2i();var largest_count=0
	for y in h:
		for x in w:
			var seed=y*w+x
			if visited[seed] or image.get_pixel(x,y).a<.08:continue
			var points=PackedInt32Array([seed]);var at=0;var lo=Vector2i(x,y);var hi=lo
			visited[seed]=1
			while at<points.size():
				var cell=points[at];at+=1;var px=cell%w;var py=int(cell/w)
				lo=lo.min(Vector2i(px,py));hi=hi.max(Vector2i(px,py))
				for delta in [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1)]:
					var q=Vector2i(px,py)+delta
					if q.x<0 or q.y<0 or q.x>=w or q.y>=h:continue
					var index=q.y*w+q.x
					if visited[index] or image.get_pixel(q.x,q.y).a<.08:continue
					visited[index]=1;points.append(index)
			if points.size()>largest_count:largest_count=points.size();largest=Rect2i(lo,hi-lo+Vector2i.ONE)
	if not largest.has_area():return
	largest=largest.grow(2)
	for y in h:
		for x in w:
			if not largest.has_point(Vector2i(x,y)):image.set_pixel(x,y,Color.TRANSPARENT)

func run():
	for bank in SOURCES:
		var source_path = "res://art_source/lion_elder/" + SOURCES[bank]
		var source = Image.load_from_file(source_path)
		if source == null or source.is_empty():
			push_error("Missing lion study: " + source_path)
			quit(1)
			return
		var folder = ROOT + bank
		if DirAccess.make_dir_recursive_absolute(folder) != OK:
			quit(1)
			return
		var frames = []
		for i in 16:
			var col = i % 4
			var row = int(i / 4)
			var lo = Vector2i(int(col * source.get_width() / 4.0), int(row * source.get_height() / 4.0))
			var hi = Vector2i(int((col + 1) * source.get_width() / 4.0), int((row + 1) * source.get_height() / 4.0))
			var rect = Rect2i(lo, hi - lo)
			var image = source.get_region(rect)
			image.convert(Image.FORMAT_RGBA8)
			key_background(image)
			isolate_cell(image)
			var used = image.get_used_rect()
			if not used.has_area():
				push_error("Empty lion frame " + bank + str(i))
				quit(1)
				return
			var sx = 0.0
			var weight = 0.0
			for y in range(maxi(used.position.y, used.end.y - 4), used.end.y):
				for x in range(used.position.x, used.end.x):
					var alpha = image.get_pixel(x, y).a
					if alpha > 0.4:
						sx += x * alpha
						weight += alpha
			var filename = "%02d.png" % i
			if image.save_png(folder + "/" + filename) != OK:
				quit(1)
				return
			frames.append({"frame": i, "file": filename, "anchor": sx / weight if weight > 0 else used.get_center().x,
				"baseline": used.end.y, "width": image.get_width(), "height": image.get_height(),
				"source_rect": [lo.x, lo.y, rect.size.x, rect.size.y], "approved": false,
				"anchor_status": "PROVISIONAL_PIXEL_CONTACT_NOT_AUTHORED_FOOT"})
		var manifest = {"schema": 1, "bank": bank, "status": "INCOMPLETE", "source": source_path,
			"source_facing": -1, "study_frame_count": 16, "approved_production_count": 0,
			"production_target_total": 272, "reference_height": 120 if bank == "lion" else 86,
			"warnings": [WARNINGS[bank], "Study only, not production. Pixel contact is not verified anatomical support. No fluency acceptance. See art_source/lion_elder/art-direction.md."],
			"frames": frames}
		var file = FileAccess.open(folder + "/frames.json", FileAccess.WRITE)
		if file == null:
			quit(1)
			return
		file.store_string(JSON.stringify(manifest, "\t") + "\n")
	print("LION_PREPARE_RESULT study=48 approved_production=0 target=272 status=INCOMPLETE")
	quit(0)
