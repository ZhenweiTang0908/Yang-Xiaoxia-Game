extends SceneTree
var game
var failed=[]
func check(ok,label):
 if ok:print("PASS ",label)
 else:failed.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 for enemy in game.enemies:enemy.set_physics_process(false);enemy.dead=true
 var enemy=game.enemies[0];enemy.dead=false;enemy.visible=true;enemy.offscreen=false;enemy.kind="dart";enemy.position=Vector2(500,450);enemy.target=Vector2(700,430);enemy.facing=1
 game.combat.clear();enemy.perform_attack()
 check(enemy.strike>0 and enemy.release_delay>.05,"attack pose starts before release")
 check(game.combat.shots.is_empty(),"projectile does not leave during pose transition")
 enemy.release_delay=.001;enemy._physics_process(.01)
 check(game.combat.shots.size()==3,"three darts appear at release point")
 check(game.combat.shots.all(func(s):return s.origin.distance_to(enemy.position-Vector2(0,enemy.body_height*.5))<.01),"projectiles share visual body origin")
 var pouncer=game.enemies[1];pouncer.set_physics_process(false);pouncer.dead=false;pouncer.visible=true;pouncer.offscreen=false;pouncer.kind="pouncer";pouncer.position=Vector2(800,450);pouncer.target=Vector2(900,450);pouncer.facing=1;pouncer.velocity=Vector2.ZERO
 game.combat.clear();pouncer.perform_attack();pouncer._physics_process(.02)
 check(pouncer.velocity.x<230 and game.combat.hazards.is_empty(),"pounce waits for pose release")
 pouncer.release_delay=.001;pouncer._physics_process(.01)
 check(pouncer.velocity.y<0 and game.combat.hazards.size()==1 and game.combat.hazards[0].kind=="pounce_impact","pounce movement and semantic impact release together")

 var shaman=game.enemies[2];shaman.set_physics_process(false);shaman.dead=false;shaman.visible=true;shaman.offscreen=false;shaman.kind="shaman";shaman.position=Vector2(1000,450);shaman.target=Vector2(1100,450)
 game.combat.clear();shaman.release_attack()
 check(game.combat.hazards.size()==1 and game.combat.hazards[0].kind=="binding_rune","shaman releases a readable binding rune")
 game.audio.stop_all();game.queue_free();await process_frame;print("ENEMY_ATTACK_RELEASE failures=",failed);quit(failed.size())
