extends SceneTree
# Offline review sheet: composites extracted frames with the authored support
# point and baseline so crop gaps and floating feet are visible headlessly.
const ROOT="res://assets/art/lion_elder_frames/"
const OUT="res://builds/qa/lion-elder/"
const MIN_CELL=Vector2i(300,300)
const BANKS=[]
func _initialize():call_deferred("run")
func run():
	DirAccess.make_dir_recursive_absolute(OUT)
	var banks=BANKS.duplicate()
	if banks.is_empty():
		for folder in DirAccess.get_directories_at(ROOT):
			if FileAccess.file_exists(ROOT+folder+"/frames.json"):banks.append(folder)
	banks.sort()
	var warnings=0
	for bank in banks:
		var path=ROOT+bank+"/frames.json"
		if not FileAccess.file_exists(path):push_error("missing "+path);quit(1);return
		var info=JSON.parse_string(FileAccess.get_file_as_string(path))
		var frames=info.frames
		# Size cells to the bank's largest crop so a tall toss never spills into
		# the neighbouring cell and reads as a clipped head.
		# Frames sit on their anchor, as in game, so a support point that jumps
		# from foot to hand shows up as the body sliding sideways between cells.
		var cell_size=MIN_CELL
		var left=0;var right=0
		for entry in frames:
			var size=Image.load_from_file(ROOT+bank+"/"+entry.file).get_size()
			left=maxi(left,int(ceil(float(entry.anchor))));right=maxi(right,size.x-int(float(entry.anchor)))
			cell_size.y=maxi(cell_size.y,size.y+50)
		cell_size.x=maxi(cell_size.x,2*maxi(left,right)+20)
		var cols=mini(5,frames.size());var rows=int(ceil(frames.size()/float(cols)))
		var sheet=Image.create(cols*cell_size.x,rows*cell_size.y,false,Image.FORMAT_RGBA8)
		sheet.fill(Color(.10,.12,.16,1))
		for index in frames.size():
			var entry=frames[index]
			var cell=Image.load_from_file(ROOT+bank+"/"+entry.file)
			if cell==null:push_error("missing frame "+entry.file);quit(1);return
			cell.convert(Image.FORMAT_RGBA8)
			var origin=Vector2i((index%cols)*cell_size.x,(int(index/cols))*cell_size.y)
			for y in cell_size.y:
				for x in cell_size.x:
					sheet.set_pixel(origin.x+x,origin.y+y,Color(.18,.20,.26,1) if (int(x/30)+int(y/30))%2==0 else Color(.22,.24,.30,1))
			var at=origin+Vector2i(int(cell_size.x*.5-float(entry.anchor)),int(cell_size.y-cell.get_height()-40))
			sheet.blend_rect(cell,Rect2i(Vector2i.ZERO,cell.get_size()),at)
			for y in range(origin.y,origin.y+cell_size.y,4):
				sheet.set_pixel(origin.x+int(cell_size.x*.5),y,Color(.55,.75,1,1))
			var support=Vector2i(at.x+int(float(entry.anchor)),at.y+int(entry.baseline))
			for x in range(origin.x,origin.x+cell_size.x):
				sheet.set_pixel(x,support.y,Color(.95,.35,.35,1))
			for y in range(support.y-3,support.y+4):
				for x in range(support.x-3,support.x+4):
					if x>=origin.x and x<origin.x+cell_size.x and y>=origin.y and y<origin.y+cell_size.y:sheet.set_pixel(x,y,Color(1,.85,.25,1))
			var used=cell.get_used_rect()
			# The bottom edge is the authored ground baseline, so only side and top
			# contact signal a limb or head cut off by the cell boundary.
			if used.position.x<=0 or used.position.y<=0 or used.end.x>=cell.get_width():
				print("CLIP_WARNING ",bank,"/",index," used=",used," cell=",cell.get_size());warnings+=1
			if entry.get("edge_contact",false):
				print("CUT_BY_BAND ",bank,"/",index);warnings+=1
		var out=OUT+"sheet-"+bank+".png"
		if sheet.save_png(out)!=OK:push_error("save failed "+out);quit(1);return
		print("SHEET ",bank," frames=",frames.size())
	print("LION_CONTACT_SHEET_RESULT banks=",banks.size()," warnings=",warnings)
	quit(0 if warnings==0 else 1)
