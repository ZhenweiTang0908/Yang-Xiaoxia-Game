extends SceneTree
class Ground:
 extends Node2D
 var offset=0.0
 var floor_y=560.0
 func _draw():
  draw_rect(Rect2(0,floor_y,960,100),Color("243941"))
  draw_line(Vector2(0,floor_y),Vector2(960,floor_y),Color("6b817f"),1)
  for i in 17:
   var x=i*64-fposmod(offset,64)
   draw_line(Vector2(x,floor_y+2),Vector2(x,floor_y+13),Color("59716f"),2)
func _initialize():call_deferred("run")
func run():
 var detail=OS.get_cmdline_user_args().has("--detail")
 var zoom=4.0 if detail else 2.0;var floor_y=800.0 if detail else 560.0
 root.size=Vector2i(960,900 if detail else 650);root.content_scale_size=root.size;Engine.max_fps=60;Engine.max_physics_steps_per_frame=1
 var bg=ColorRect.new();bg.size=Vector2(root.size);bg.color=Color("18262c");root.add_child(bg)
 var ground=Ground.new();ground.floor_y=floor_y;root.add_child(ground)
 var rig=load("res://tests/hero_combo_gait.gd").new();root.add_child(rig);rig.posing=true;rig.scale=Vector2.ONE*rig.game_scale*zoom
 var timeline=load("res://tests/action_timeline.gd").new(rig)
 var target=load("res://tests/practice_target.gd").new();target.scale=rig.scale;root.add_child(target)
 var consumed_events=0
 DirAccess.make_dir_recursive_absolute("res://builds/qa/action-frames")
 for i in 252:
  timeline.advance_to(i/60.0)
  target.step(1.0/60)
  while consumed_events<timeline.events.size():
   var event=timeline.events[consumed_events];consumed_events+=1
   if event.has("damage"):target.strike(event.damage)
  rig.position=Vector2(400,floor_y)+Vector2(-96,-199+timeline.height)*rig.game_scale*zoom
  target.position=Vector2(400+(timeline.TARGET_TRAVEL-rig.travel_x)*zoom,floor_y)+Vector2(38,-64)*rig.game_scale*zoom
  ground.offset=rig.travel_x*zoom;ground.queue_redraw()
  await process_frame;await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://builds/qa/action-frames/%04d.png"%i)
 var events=[]
 for event in timeline.events:events.append({"frame":int(round(event.time*60)),"path":event.path})
 var file=FileAccess.open("res://builds/qa/action-audio.json",FileAccess.WRITE);file.store_string(JSON.stringify({"fps":60,"frames":252,"events":events},"  "));file.close()
 print("ACTION_CAPTURE audio_events=",events.size()," hits=",target.hits," foot_releases=",rig.released_unreachable)
 quit()
