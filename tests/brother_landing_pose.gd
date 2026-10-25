extends SceneTree
var errors=[]
func _initialize():call_deferred("run")
func check(ok,label):
 print("PASS " if ok else "FAIL ",label)
 if not ok:errors.append(label)
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 for enemy in game.enemies:enemy.set_physics_process(false);enemy.dead=true
 game.player.health=100;game.progress.gourd=true;game.summon.reset(true);game.summon.request()
 for i in 85:await physics_frame
 var brother=game.summon.brother;brother.set_physics_process(false);game.combat.set_physics_process(false)
 var target=game.enemies[0];target.dead=false;game.player.current_target=target
 var visual=brother.skeletal_visual
 visual.landing_sink=0
 var head=visual.deform(Vector2(0,-60),[0,0,0,0])
 var collar=visual.deform(Vector2(0,-40),[0,0,0,0])
 var foot=visual.deform(Vector2(0,0),[0,0,0,0])
 visual.landing_sink=2
 check(visual.deform(Vector2(0,0),[0,0,0,0])==foot,"sole stays pinned")
 check(visual.deform(Vector2(0,-60),[0,0,0,0])-head==visual.deform(Vector2(0,-40),[0,0,0,0])-collar,"head and collar translate together")
 check(visual.deform(Vector2(0,-60),[0,0,0,0]).y==head.y+2,"landing has restrained two-pixel sink")
 game.audio.stop_all();await create_timer(.1).timeout;game.queue_free();await process_frame
 print("BROTHER_CARD_RELEASE failures=",errors)
 quit(0 if errors.is_empty() else 1)
