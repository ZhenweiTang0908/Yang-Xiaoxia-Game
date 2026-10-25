extends SceneTree
class Samples:
 extends "res://scripts/combat/projectile_visual.gd"
 func _draw():
  for i in 5:
   draw_ending({"elapsed":i*.035,"p":Vector2(20+i*30,30),"v":Vector2.RIGHT,"kind":"card","faction":"brother","age":.1})
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(800,300)
 var bg=ColorRect.new();bg.size=Vector2(800,300);bg.color=Color("18262c");root.add_child(bg)
 var sample=Samples.new();sample.scale=Vector2.ONE*5;root.add_child(sample)
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/card-fade.png")
 quit()
