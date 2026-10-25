extends SceneTree
func _initialize():call_deferred("run")
func run():
 var rig=load("res://tests/hero_layer_study.gd").new();root.add_child(rig)
 var area=0.0
 for mesh in rig.parts:
  var vertices=mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
  for i in range(0,vertices.size(),4):area+=(vertices[i+1].x-vertices[i].x)*(vertices[i+2].y-vertices[i].y)
 var errors=0
 if absf(area-rig.opaque_pixels)>.01:errors+=1
 if rig.strip_count>=rig.opaque_pixels/4:errors+=1
 var img=Image.load_from_file("res://builds/qa/layers-rest.png")
 var different=0
 for y in range(80,580):
  for x in range(70,620):
   if img.get_pixel(x,y)!=img.get_pixel(x+580,y):different+=1
 if different>0:errors+=1
 print("LAYER_REST pixels=",rig.opaque_pixels," strips=",rig.strip_count," area=",area," screenshot_differences=",different," errors=",errors)
 rig.queue_free();await process_frame;quit(errors)
