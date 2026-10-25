extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false);game.hide();game.set_process(false)
 var actor=game.enemies[0];actor.kind="bat";actor.strike=0;actor.dead=false
 for enemy in game.enemies:enemy.set_physics_process(false)
 var bg=ColorRect.new();bg.size=Vector2(960,540);bg.color=Color("18262c");root.add_child(bg)
 var inverted=0
 for i in 4:
  var art=load("res://scripts/actors/enemy_art.gd").new();root.add_child(art)
  art.configure("res://assets/art/v2/mobs.png",6,8,70);art.actor=actor;art.frame=24;art.prepare(24);art.set_process(false)
  art.clock=float(i)/4/3.5;art.position=Vector2(130+i*210,300);art.queue_redraw()
  var indices=art.arrays[Mesh.ARRAY_INDEX]
  for n in range(0,indices.size(),3):
   var a=art.deform(art.rest[indices[n]]);var b=art.deform(art.rest[indices[n+1]]);var c=art.deform(art.rest[indices[n+2]])
   if (b-a).cross(c-a)<=0:inverted+=1
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/bat-wings.png")
 print("BAT_WING inverted_triangles=",inverted)
 game.audio.stop_all();game.queue_free();await process_frame;await create_timer(.1).timeout;quit(0 if inverted==0 else 1)
