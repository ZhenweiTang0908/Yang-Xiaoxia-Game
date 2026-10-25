extends SceneTree
func _initialize():call_deferred("run")
func run():
 var atlas=load("res://scripts/actors/atlas_actor.gd").new();atlas.configure("res://assets/art/v2/bosses.png",6,3,90)
 var source=atlas.texture.get_image();var report=[]
 for index in 18:
  var image=source.get_region(Rect2i(atlas.regions[index]));image.convert(Image.FORMAT_RGBA8)
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
  clean.save_png("res://assets/art/boss_frames/%02d.png"%index)
  report.append({"frame":index,"components":components.size(),"retained_pixels":keep.size(),"removed_pixels":components.slice(1).reduce(func(total,c):return total+c.size(),0)})
 FileAccess.open("res://builds/qa/boss-isolation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
 atlas.free();print("ISOLATED_BOSS_FRAMES 18");quit()
