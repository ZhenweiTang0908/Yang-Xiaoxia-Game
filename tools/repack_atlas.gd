extends SceneTree
# Repack a painted action atlas whose poses overflow their grid cells.
# Each connected silhouette piece is assigned to the frame whose cell holds its
# centre of mass, then copied into a wider cell at the same offset from the old
# cell's centre/top. atlas_actor anchors on the cell centre and the feet, so the
# repacked frames land exactly where they did before, minus neighbours' fragments.
# Usage: Godot --headless --path . --script tools/repack_atlas.gd
const JOBS=[
	{"source":"res://assets/art/v2/sheep.png","target":"res://assets/art/v2/sheep_clean.png","cols":6,"rows":4,"edges":[0,264,493,741,1024],"keyed":true},
	{"source":"res://assets/art/v2/hero.png","target":"res://assets/art/v2/hero_clean.png","cols":8,"rows":5,"edges":[0,208,386,571,790,1086],"keyed":false},
]
const PAD=Vector2i(72,36)
func _initialize():
	for job in JOBS:repack(job)
	quit()
func solid(img,x,y,keyed):
	var c=img.get_pixel(x,y)
	if c.a<=.1:return false
	return not (keyed and c.r>.65 and c.b>.65 and c.g<.4)
func repack(job):
	var img:Image=load(job.source).get_image()
	img.decompress()
	if img.get_format()!=Image.FORMAT_RGBA8:img.convert(Image.FORMAT_RGBA8)
	var w=img.get_width();var h=img.get_height();var keyed=job.keyed
	var cols=job.cols;var rows=job.rows;var edges=job.edges
	var cell_w=w/cols
	var row_h=0
	for r in rows:row_h=maxi(row_h,edges[r+1]-edges[r])
	var out_cell=Vector2i(cell_w+PAD.x*2,row_h+PAD.y*2)
	var out=Image.create(out_cell.x*cols,out_cell.y*rows,false,Image.FORMAT_RGBA8)
	out.fill(Color(1,0,1,1) if keyed else Color(0,0,0,0))
	var labels=PackedInt32Array();labels.resize(w*h);labels.fill(-1)
	var moved=0
	for y in h:
		for x in w:
			if labels[y*w+x]!=-1 or not solid(img,x,y,keyed):continue
			# Flood fill one 8-connected piece.
			var piece=PackedInt32Array();var stack=PackedInt32Array([y*w+x]);labels[y*w+x]=0
			var sx=0.0;var sy=0.0
			while not stack.is_empty():
				var i=stack[stack.size()-1];stack.resize(stack.size()-1)
				piece.append(i);var px=i%w;var py=i/w;sx+=px;sy+=py
				for dy in [-1,0,1]:
					for dx in [-1,0,1]:
						var nx=px+dx;var ny=py+dy
						if nx<0 or ny<0 or nx>=w or ny>=h:continue
						var j=ny*w+nx
						if labels[j]==-1 and solid(img,nx,ny,keyed):labels[j]=0;stack.append(j)
			var cx=sx/piece.size();var cy=sy/piece.size()
			var col=clampi(int(cx/cell_w),0,cols-1);var row=0
			for r in rows:
				if cy>=edges[r]:row=r
			var origin=Vector2i(col*cell_w,edges[row])
			var target=Vector2i(col*out_cell.x,row*out_cell.y)+PAD
			for i in piece:
				var p=Vector2i(i%w,i/w);var q=target+p-origin
				if q.x<col*out_cell.x or q.y<row*out_cell.y or q.x>=(col+1)*out_cell.x or q.y>=(row+1)*out_cell.y:continue
				out.set_pixelv(q,img.get_pixelv(p))
				if p.x<origin.x or p.x>=origin.x+cell_w or p.y<edges[row] or p.y>=edges[row+1]:moved+=1
	out.save_png(ProjectSettings.globalize_path(job.target))
	print("REPACK ",job.target," cell=",out_cell," pixels restored across cell edges=",moved)
