extends SceneTree
class Preview:
 extends Node2D
 func _draw():
  draw_rect(Rect2(0,0,700,360),Color("18262c"))
  var shapes=load("res://scripts/combat/vfx_shapes.gd")
  for i in 4:
   var p=Vector2(90+i*165,40)
   shapes.bolt(self,p,p+Vector2(0,120),.4,Color(1,.6,.3,1.0-i*.3))
   shapes.bolt(self,p+Vector2(-45,220),p+Vector2(65,260),.4,Color(1,.6,.3,1.0-i*.3))
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(700,360);root.content_scale_size=root.size
 root.add_child(Preview.new())
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/bolt-fade.png")
 quit()
