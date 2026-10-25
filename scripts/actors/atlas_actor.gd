extends Node2D
static var metadata={}
var texture:Texture2D
var columns=6
var rows=4
var bounds:Array=[]
var regions:Array=[]
var scale_unit=1.0
var frame=0
var facing=1.0
var tint=Color.WHITE
var motion=Vector2.ZERO
var pivot_override=Vector2.INF
var body_height=53.0
func configure(path:String,cols:int,row_count:int,height:float):
	texture=load(path);columns=cols;rows=row_count;body_height=height
	var keyed=path.ends_with("/niu.png") or path.ends_with("/sheep.png") or path.ends_with("/sheep_clean.png") or "/v3/" in path
	if keyed:
		material=ShaderMaterial.new();material.shader=load("res://scripts/actors/chroma.gdshader")
	if metadata.has(path):
		bounds=metadata[path].bounds;regions=metadata[path].regions
	else:
		bounds=[];regions=[]
		var img=texture.get_image()
		var y_edges=[]
		for row in rows+1:y_edges.append(int(float(row)/rows*img.get_height()))
		if path.ends_with("/hero.png"):
			y_edges=[0,208,386,571,790,1086]
		elif path.ends_with("/niu_human.png"):
			y_edges=[0,256,510,751,1024]
		elif path.ends_with("/niu.png"):
			y_edges=[0,256,500,750,1024]
		elif path.ends_with("/sheep.png"):
			y_edges=[0,264,493,741,1024]
		elif path.ends_with("/mobs.png"):
			y_edges=[0,180,342,538,724,890,1056,1236,1448]
		elif path.ends_with("/bosses.png"):
			y_edges=[0,305,560,887]
		for row in rows:
			for col in cols:
				var left=int(float(col)/cols*img.get_width());var right=int(float(col+1)/cols*img.get_width())
				var area=Rect2i(left,y_edges[row],right-left,y_edges[row+1]-y_edges[row])
				if path.ends_with("/bosses.png"):
					var cuts=[Rect2i(4,0,263,305),Rect2i(278,0,280,305),Rect2i(558,0,264,305),Rect2i(830,0,389,305),Rect2i(1220,0,250,305),Rect2i(1480,0,294,305),Rect2i(5,330,269,223),Rect2i(283,330,272,223),Rect2i(562,330,258,223),Rect2i(822,330,402,223),Rect2i(1228,330,247,223),Rect2i(1480,330,294,223),Rect2i(0,553,279,334),Rect2i(280,553,275,334),Rect2i(556,548,265,339),Rect2i(822,556,405,331),Rect2i(1228,556,248,331),Rect2i(1478,556,296,331)]
					area=cuts[row*cols+col]
				regions.append(Rect2(area))
				if keyed:
					var lo=Vector2i(area.size);var hi=Vector2i.ZERO
					for y in area.size.y:
						for x in area.size.x:
							var pixel=img.get_pixel(area.position.x+x,area.position.y+y)
							if pixel.a>.1 and not (pixel.r>.65 and pixel.b>.65 and pixel.g<.4):
								lo=lo.min(Vector2i(x,y));hi=hi.max(Vector2i(x+1,y+1))
					bounds.append(Rect2i(lo,hi-lo))
				else:bounds.append(img.get_region(area).get_used_rect())
		metadata[path]={"bounds":bounds,"regions":regions}
	var reference=0.0
	for i in cols:reference=maxf(reference,bounds[i].size.y)
	scale_unit=height/maxf(reference,1);queue_redraw()
func _process(_dt):queue_redraw()
func _draw():
	if not texture or bounds.is_empty():return
	var index=clampi(frame,0,bounds.size()-1);var used=bounds[index];var src=regions[index]
	var baseline=float(used.end.y);var anchor=src.size.x*.5
	if texture.resource_path.ends_with("/bull.png"):baseline=382 if index<4 else 350
	if pivot_override.is_finite():anchor=pivot_override.x;baseline=pivot_override.y
	draw_set_transform(motion,0,Vector2(facing,1))
	draw_texture_rect_region(texture,Rect2(Vector2(-anchor,-baseline)*scale_unit,src.size*scale_unit),src,tint)
