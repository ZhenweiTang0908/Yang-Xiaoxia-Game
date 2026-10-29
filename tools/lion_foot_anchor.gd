extends SceneTree
# Proposes support overrides for frames whose lowest pixels are a hand or the
# lion head. Shoes are the only tall dark blocks at the ground line; outlines
# under a palm or jaw are a pixel or two thick.
const ROOT="res://assets/art/lion_elder_frames/"
const SKIP=["lion","backfall","sweep"]
func _initialize():call_deferred("run")
func run():
	var banks=[]
	for folder in DirAccess.get_directories_at(ROOT):
		if not SKIP.has(folder) and FileAccess.file_exists(ROOT+folder+"/frames.json"):banks.append(folder)
	banks.sort()
	for bank in banks:
		var info=JSON.parse_string(FileAccess.get_file_as_string(ROOT+bank+"/frames.json"))
		for entry in info.frames:
			var image=Image.load_from_file(ROOT+bank+"/"+entry.file)
			var base=int(entry.baseline)
			var sum=0.0;var weight=0.0;var on_shoe=false
			for x in image.get_width():
				var dark=0
				for y in range(maxi(0,base-16),mini(image.get_height(),base)):
					var c=image.get_pixel(x,y)
					if c.a>.8 and c.get_luminance()<.16:dark+=1
				if dark>=6:
					sum+=x;weight+=1
					if absf(x-float(entry.anchor))<=20:on_shoe=true
			if on_shoe:continue
			if weight<4:print("NO_SHOE ",bank,"/",entry.frame);continue
			var foot=sum/weight
			print("OVERRIDE ",bank," ",entry.frame," ",snappedf(foot,.1)," ",base," was ",snappedf(float(entry.anchor),.1))
	print("LION_FOOT_ANCHOR_RESULT done")
	quit(0)
