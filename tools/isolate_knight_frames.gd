extends SceneTree
# Same transparent PNG/isolated-frame pipeline used by the original three bosses.
# Connected components preserve long weapons that cross nominal atlas cell margins.
func _initialize():call_deferred("run")
func run():
	var args=OS.get_cmdline_user_args()
	if args.size()!=2:push_error("Usage: -- atlas.png output_folder");quit(1);return
	var source=Image.load_from_file(args[0]);source.convert(Image.FORMAT_RGBA8)
	var w=source.get_width();var h=source.get_height();var seen=PackedByteArray();seen.resize(w*h)
	var groups=[]
	for i in 12:groups.append([])
	var raw=source.get_data();var components=0
	for y in h:
		for x in w:
			var start=y*w+x
			if seen[start] or raw[start*4+3]<25:continue
			var pixels=PackedInt32Array([start]);seen[start]=1;var cursor=0;var lo=Vector2i(x,y);var hi=lo
			while cursor<pixels.size():
				var cell=pixels[cursor];cursor+=1;var px=cell%w;var py=cell/w
				lo=lo.min(Vector2i(px,py));hi=hi.max(Vector2i(px,py))
				for off in [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1),Vector2i(-1,-1),Vector2i(1,1),Vector2i(-1,1),Vector2i(1,-1)]:
					var nx=px+off.x;var ny=py+off.y
					if nx<0 or nx>=w or ny<0 or ny>=h:continue
					var n=ny*w+nx
					if not seen[n] and raw[n*4+3]>=25:seen[n]=1;pixels.append(n)
			if pixels.size()<24:continue
			components+=1
			var center=(Vector2(lo)+Vector2(hi))*.5
			var col=clampi(int(center.x/w*4),0,3);var row=clampi(int(center.y/h*3),0,2)
			groups[row*4+col].append({"pixels":pixels,"lo":lo,"hi":hi})
	DirAccess.make_dir_recursive_absolute(args[1])
	var manifest=[]
	for i in 12:
		if groups[i].is_empty():push_error("Missing painted knight frame "+str(i));quit(1);return
		var lo=Vector2i(w,h);var hi=Vector2i.ZERO
		for c in groups[i]:lo=lo.min(c.lo);hi=hi.max(c.hi)
		var margin=8;var size=hi-lo+Vector2i.ONE+Vector2i.ONE*margin*2
		var clean=Image.create(size.x,size.y,false,Image.FORMAT_RGBA8)
		for c in groups[i]:
			for pixel in c.pixels:clean.set_pixel(pixel%w-lo.x+margin,pixel/w-lo.y+margin,source.get_pixel(pixel%w,pixel/w))
		var used=clean.get_used_rect();var sx=0.0;var sw=0.0
		# The support-foot strip anchors a pose, never its spear tip.
		var baseline=used.position.y
		for py in range(used.position.y,used.end.y):
			for px in range(int(used.position.x+used.size.x*.45),used.end.x):
				if clean.get_pixel(px,py).a>.4:baseline=maxi(baseline,py+1)
		var support_top=baseline-maxi(4,int(used.size.y*.03))
		var support_left=used.position.x+used.size.x*.08
		var support_right=used.end.x
		for py in range(support_top,baseline):
			for px in range(int(support_left),int(support_right)):
				var alpha=clean.get_pixel(px,py).a
				if alpha>.4:sx+=px*alpha;sw+=alpha
		var anchor=sx/sw if sw>0 else used.get_center().x
		# Gallop support changes between four feet. Anchor the barrel/saddle instead,
		# otherwise each contact would teleport the whole horse sideways.
		if args[1].ends_with("/mounted"):
			var saddle_x=[175,551,916,1277,194,571,938,1310,195,561,938,1320]
			anchor=float(saddle_x[i])-lo.x+margin;baseline=used.end.y
		elif args[1].ends_with("/arsenal") and i<4:
			var saddle_x=[205,559,925,1295]
			anchor=float(saddle_x[i])-lo.x+margin;baseline=used.end.y
		elif args[1].ends_with("/extra") and i<6:
			var barrel_x=[199,550,920,1277,203,576]
			anchor=float(barrel_x[i])-lo.x+margin;baseline=used.end.y
		clean.save_png(args[1]+"/%02d.png"%i)
		manifest.append({"frame":i,"anchor":anchor,"baseline":baseline,"width":size.x,"height":size.y,"source_rect":[lo.x,lo.y,hi.x-lo.x+1,hi.y-lo.y+1]})
	FileAccess.open(args[1]+"/frames.json",FileAccess.WRITE).store_string(JSON.stringify(manifest,"  "))
	print("ISOLATED_KNIGHT_FRAMES 12 components=",components," ",args[1]);quit()
