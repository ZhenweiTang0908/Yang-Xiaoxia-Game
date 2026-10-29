extends SceneTree
func _initialize():call_deferred("run")
func run():
	for filename in DirAccess.get_files_at("res://art_source/lion_elder/production"):
		if not filename.ends_with(".png"):continue
		var image=Image.load_from_file("res://art_source/lion_elder/production/"+filename)
		if image==null:quit(1);return
		var transparent=0
		for y in range(0,image.get_height(),8):
			for x in range(0,image.get_width(),8):
				if image.get_pixel(x,y).a<.1:transparent+=1
		print(filename," corner=",image.get_pixel(0,0)," transparent_samples=",transparent," used=",image.get_used_rect())
	print("LION_SOURCES_RESULT diagnostic=complete; not production approval")
	quit(0)
