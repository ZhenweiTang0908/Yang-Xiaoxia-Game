extends SceneTree
class Preview:
 extends Node2D
 func _draw():
  draw_rect(Rect2(0,0,700,360),Color("18262c"))
  for i in 4:
   var hazard={"kind":"lightning" if i<2 else "rain","rect":Rect2(70+i*155,70,50,180),"warning_total":1.0,"delay":.8 if i%2==0 else .1}
   preload("res://scripts/combat/skill_finish.gd").warning(self,hazard)
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(700,360);root.content_scale_size=root.size;root.add_child(Preview.new())
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/falling-warnings.png");quit()
