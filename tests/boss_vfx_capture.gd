extends SceneTree
# Render real warning, active and fading frames: headless compilation cannot catch
# invalid polygons or unsupported calls reached only from CanvasItem._draw().
const OUT="res://builds/qa/boss-vfx/"
var game
var frames=0
func _initialize():
 root.unfocusable=true
 call_deferred("run")
func capture(label):
 game.boss.queue_redraw()
 await process_frame
 RenderingServer.force_draw(false)
 var picture=root.get_texture().get_image()
 if picture==null or picture.is_empty():
  push_error("Empty VFX capture: "+label)
  quit(1)
  return
 picture.save_png(OUT+label+".png")
 frames+=1
func run():
 DirAccess.make_dir_recursive_absolute(OUT)
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.qa_mode=true
 game.start_new()
 root.size=Vector2i(960,540)
 game.set_physics_process(false)
 for stage in [1,2,3]:
  game.jump_to_stage(stage)
  await process_frame
  game.player.set_physics_process(false)
  game.summon.set_physics_process(false)
  game.combat.set_physics_process(false)
  var b=game.boss
  b.set_physics_process(false)
  game.stage_banner=-10
  for index in b.spec.moves.size():
   game.state="playing"
   b.clear_attacks()
   b.hp=b.max_hp
   b.phase=1
   b.phase_shift=0
   b.cooldown=999
   b.active_battle=true
   b.position=Vector2(650,450)
   b.facing=-1
   game.player.position=Vector2(390,450)
   game.player.invincible=999
   b.start_move(index)
   var windup=b.windup
   var elapsed=0.0
   var samples=[windup*.5,windup+.03,windup+.10,windup+.27,windup+.65,windup+1.05,windup+1.5,windup+1.75]
   for sample in samples.size():
    while elapsed<samples[sample]:
     game.hitstop=0
     b._physics_process(1.0/60)
     b.cooldown=999
     elapsed+=1.0/60
    await capture(str(stage)+"-"+str(b.spec.moves[index].id)+"-"+str(sample))
  b.clear_attacks()
 game.audio.stop_all()
 game.queue_free()
 await process_frame
 print("BOSS_VFX_CAPTURE_RESULT frames=",frames)
 quit(0)
