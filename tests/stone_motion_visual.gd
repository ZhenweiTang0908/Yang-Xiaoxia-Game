extends SceneTree
class Sample:
 extends Node2D
 var age=0.0
 var width=44.0
 func _draw():
  draw_line(Vector2(-8,30),Vector2(width+8,30),Color("52665f"),1)
  preload("res://scripts/combat/stone_motion.gd").draw_effect(self,{"rect":Rect2(0,0,width,30),"age":age,"total":.3})
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(960,540);root.content_scale_size=root.size
 var bg=ColorRect.new();bg.size=Vector2(960,540);bg.color=Color("18262c");root.add_child(bg)
 for row in 2:
  for i in 3:
   var sample=Sample.new();sample.age=[.02,.15,.29][i];sample.width=44 if row==0 else 96;sample.position=Vector2(90+i*300,130+row*210);sample.scale=Vector2.ONE*2;root.add_child(sample)
   var label=Label.new();label.text="%.2f s"%sample.age;label.position=sample.position+Vector2(35,80);root.add_child(label)
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/stone-motion-phases.png");quit()
