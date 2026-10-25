extends SceneTree
var failed=0
func check(ok,label):
 if not ok:failed+=1;push_error(label)
 else:print("PASS ",label)
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 for e in game.enemies:e.set_physics_process(false);e.dead=true
 game.progress.gourd=true;game.summon.reset(true);game.summon.request();await create_timer(1.4).timeout
 var brother=game.summon.brother;var target=game.boss;target.dead=false;target.active_battle=true;target.position=brother.position+Vector2(220,0)
 game.combat.clear();brother.release_card(target)
 check(game.combat.shots.size()==1 and game.combat.shots[0].variant=="plain","normal card uses diamond mark")
 game.combat.clear();brother.release_fan(target)
 check(game.combat.shots.size()==3 and game.combat.shots.all(func(s):return s.variant=="leaf"),"fan cards use leaf mark")
 game.combat.clear();brother.release_return(target)
 check(game.combat.shots.size()==1 and game.combat.shots[0].variant=="loop","return card uses loop mark")
 game.combat.shots[0].life=0;game.combat._physics_process(.01)
 check(game.combat.shot_endings.size()==1 and game.combat.shot_endings[0].variant=="loop","card mark persists through fade")
 game.audio.stop_all();game.queue_free();await process_frame;print("CARD_VARIANTS failures=",failed);quit(failed)
