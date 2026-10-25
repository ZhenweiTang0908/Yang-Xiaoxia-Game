extends SceneTree
func _initialize():call_deferred("run")
func run():
 clean_atlas("hero",8,5)
 clean_atlas("uppercut",4,2)
 quit()
func clean_atlas(label,cols,rows):
 var atlas=load("res://scripts/actors/atlas_actor.gd").new();atlas.configure("res://assets/art/v2/"+label+".png",cols,rows,52.8)
 var source=atlas.texture.get_image();var report=[];var manifest=[]
 DirAccess.make_dir_recursive_absolute("res://assets/art/hero_2d/"+label)
 var output=Image.create(source.get_width(),source.get_height(),false,Image.FORMAT_RGBA8)
 for index in atlas.regions.size():
  var base=Rect2i(atlas.regions[index]);var area=Rect2i(maxi(0,base.position.x-28),base.position.y,base.size.x+56,base.size.y)
  area=area.intersection(Rect2i(0,0,source.get_width(),source.get_height()))
  var image=source.get_region(area);image.convert(Image.FORMAT_RGBA8)
  var w=image.get_width();var h=image.get_height();var seen=PackedByteArray();seen.resize(w*h);var components=[]
  for y in h:
   for x in w:
    var start=y*w+x
    if seen[start] or image.get_pixel(x,y).a<.35:continue
    var cells=PackedInt32Array([start]);seen[start]=1;var cursor=0
    while cursor<cells.size():
     var cell=cells[cursor];cursor+=1;var px=cell%w;var py=cell/w
     for offset in [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1),Vector2i(1,1),Vector2i(-1,-1),Vector2i(1,-1),Vector2i(-1,1)]:
      var nx=px+offset.x;var ny=py+offset.y
      if nx<0 or nx>=w or ny<0 or ny>=h:continue
      var n=ny*w+nx
      if not seen[n] and image.get_pixel(nx,ny).a>=.35:seen[n]=1;cells.append(n)
    components.append(cells)
  components.sort_custom(func(a,b):return a.size()>b.size())
  var clean=Image.create(w,h,false,Image.FORMAT_RGBA8);var keep=components[0]
  for cell in keep:clean.set_pixel(cell%w,cell/w,image.get_pixel(cell%w,cell/w))
  clean.save_png("res://assets/art/hero_2d/"+label+"/%02d.png"%index)
  var bounds=clean.get_used_rect();var offset=area.position-base.position
  manifest.append({"offset":[offset.x,offset.y],"bounds":[bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y]})
  report.append({"frame":index,"components":components.size(),"retained_pixels":keep.size(),"removed_pixels":components.slice(1).reduce(func(total,c):return total+c.size(),0)})
 FileAccess.open("res://assets/animation/"+label+"_2d_frames.json",FileAccess.WRITE).store_string(JSON.stringify(manifest))
 FileAccess.open("res://builds/qa/"+label+"-isolation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
 atlas.free();print("CLEANED ",label)
