extends SceneTree
func _initialize():
	for key in ["hero","niu","sheep","uppercut","mobs","bosses"]:
		var image=Image.load_from_file("res://assets/art/v2/"+key+".png")
		var samples=[]
		for p in [Vector2i(0,0),Vector2i(5,5),Vector2i(25,25),Vector2i(255,10)]:samples.append(image.get_pixelv(p))
		print(key," ",image.get_size()," corners=",samples)
	quit()
