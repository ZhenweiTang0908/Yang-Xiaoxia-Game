extends SceneTree
class Sheet:
 extends "res://scripts/combat/projectile_visual.gd"
 func _draw():
  for row in 2:
   for i in 5:
    draw_ending({"p":Vector2(65+i*120,65+row*110),"v":Vector2(200,0),"elapsed":i*.035,"age":.3,"kind":"flame","faction":"enemy" if row==0 else "player"})
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(640,240);root.content_scale_size=root.size
 var bg=ColorRect.new();bg.size=Vector2(root.size);bg.color=Color("14232c");root.add_child(bg)
 root.add_child(Sheet.new())
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/flame-finish.png");quit()
