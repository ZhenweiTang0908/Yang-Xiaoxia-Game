extends SceneTree
class Subject:
 extends RefCounted
 var kind="spirit"
 var dead=false
 var strike=0.0
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(960,360);root.content_scale_size=root.size
 var bg=ColorRect.new();bg.size=Vector2(960,360);bg.color=Color("18262c");root.add_child(bg)
 var subject=Subject.new();var inverted=0;var head_error=0.0
 for i in 4:
  var art=load("res://scripts/actors/enemy_art.gd").new();root.add_child(art)
  art.configure("res://assets/art/v2/mobs.png",6,8,70);art.actor=subject;art.frame=6;art.prepare(6);art.set_process(false)
  art.clock=i*TAU/4/3.6;art.position=Vector2(130+i*230,260);art.queue_redraw()
  var indices=art.arrays[Mesh.ARRAY_INDEX]
  for p in art.rest:
   var source=p/art.scale_unit+Vector2(art.anchors[6],art.bounds[6].end.y)
   if source.y<=88:head_error=maxf(head_error,p.distance_to(art.deform(p)))
  for n in range(0,indices.size(),3):
   var a=art.deform(art.rest[indices[n]]);var b=art.deform(art.rest[indices[n+1]]);var c=art.deform(art.rest[indices[n+2]])
   if (b-a).cross(c-a)<=0:inverted+=1
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/spirit-tail.png")
 print("SPIRIT_TAIL head_error=",head_error," inverted_triangles=",inverted)
 quit(0 if inverted==0 and head_error<.001 else 1)
