extends SceneTree
var failed=0
func check(value,label):
 if not value:failed+=1;push_error(label)
 else:print("PASS ",label)
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 game.set_process(false);game.player.set_physics_process(false)
 for e in game.enemies:e.set_physics_process(false)
 var target=game.enemies[0]
 for e in game.enemies:e.dead=true
 target.dead=false;target.hp=100;target.position=Vector2(500,450)
 game.player.position=Vector2(470,450);game.player.facing=1;game.player.combo=1
 game.fx.clear();game.combat.melee(game.player)
 check(game.fx.melee_contacts.size()==1,"one contact for one struck enemy")
 check(game.fx.melee_contacts[0].p.x==500-target.radius,"spark lies on facing edge of target")
 check(game.fx.particles.is_empty(),"no duplicate body-center debris")
 check(target.hp==76,"damage unchanged")
 game.fx.clear();game.player.position.x=100;game.combat.melee(game.player)
 check(game.fx.melee_contacts.is_empty(),"swinging into empty air creates no hit spark")
 for i in 30:game.fx.melee_contact(Vector2.ZERO,"stone",1)
 check(game.fx.melee_contacts.size()==12,"contact effect count capped")
 game.state="paused";game.fx._process(.3)
 check(game.fx.melee_contacts.size()==12,"pause freezes contacts")
 game.fx.game=null;game.fx._process(.21)
 check(game.fx.melee_contacts.is_empty(),"contacts disappear after 200ms")
 game.audio.stop_all();game.queue_free();await process_frame
 print("MELEE_CONTACT failures=",failed);quit(failed)
