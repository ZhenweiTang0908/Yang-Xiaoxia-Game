extends SceneTree
class Ground:
 extends Node2D
 var offset=0.0
 func _draw():
  draw_rect(Rect2(0,849,1200,51),Color("243941"))
  draw_line(Vector2(0,849),Vector2(1200,849),Color("6b817f"),1)
  for i in 21:
   var x=i*64-fposmod(offset,64)
   draw_line(Vector2(x,851),Vector2(x,862),Color("59716f"),2)
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(1200,900);root.content_scale_size=root.size
 var background=ColorRect.new();background.size=Vector2(1200,900);background.color=Color("18262c");root.add_child(background)
 var ground=Ground.new();root.add_child(ground)
 var rig=load("res://tests/hero_running_gait.gd").new();root.add_child(rig);rig.posing=true
 var timeline=load("res://tests/jump_timeline.gd").new(rig)
 DirAccess.make_dir_recursive_absolute("res://builds/qa/jump-frames")
 for i in 156:
  timeline.advance_to(i/60.0);rig.position=Vector2(550,650+timeline.height)
  ground.offset=rig.travel_x/rig.game_scale;ground.queue_redraw()
  await process_frame;await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://builds/qa/jump-frames/%04d.png"%i)
 quit()
