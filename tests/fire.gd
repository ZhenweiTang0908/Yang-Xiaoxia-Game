extends SceneTree
var game
var checks=0
var failures=[]
func check(ok,label):
 checks+=1
 if not ok:failures.append(label);push_error(label)
 else:print("PASS ",label)
func _initialize():call_deferred("run")
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.jump_to_stage(3,2)
 var b=game.boss;b.active_battle=true;b.position=Vector2(14900,450);b.facing=-1;b.set_physics_process(false)
 game.player.set_physics_process(false)
 b.start_move(6)
 check(b.windup>=1.2,"breath has full anticipation")
 b.windup=0;b.release_move()
 var h=game.combat.hazards.back()
 check(h.kind=="spirit_beam" and h.rect.size.x==330 and h.face==-1,"directional limited spirit beam")
 game.player.position=Vector2(14700,450);game.player.health=100;game.player.invincible=0
 game.combat._physics_process(.01)
 check(game.player.health==100,"unreached flame front cannot damage player")
 game.combat._physics_process(.11)
 check(game.player.health==68,"standing in flame takes configured damage")
 game.player.invincible=0;game.combat._physics_process(.01)
 check(game.player.health==68,"same breath cannot repeatedly hit")
 var front=game.combat.damage_rect(h)
 check(is_equal_approx(front.end.x,h.rect.end.x) and is_equal_approx(front.size.x,330),"leftward flame stays anchored to staff")
 h.duration=.06;front=game.combat.damage_rect(h)
 check(front.size.x>0 and front.size.x<330 and is_equal_approx(front.end.x,h.rect.end.x),"flame contracts toward staff during final 120 ms")
 h.duration=0;check(not game.combat.damage_rect(h).has_area(),"extinguished flame has no damaging area")
 game.combat.clear();b.release_move();game.player.position=Vector2(15000,450);game.player.health=100;game.player.invincible=0
 game.combat._physics_process(.12)
 check(game.player.health==100,"behind boss is safe")
 # A full jump rises about 125 px; sample at 110 px above the floor.
 game.combat.clear();b.release_move();game.player.position=Vector2(14700,340);game.player.invincible=0
 game.combat._physics_process(.12)
 check(game.player.health==100,"full jump clears staff flame with height margin")
 game.combat.clear();b.start_move(2);b.windup=0;b.release_move()
 check(game.combat.hazards.size()==16 and game.combat.hazards.all(func(z):return z.kind=="ground_rift"),"ground wave creates timed rift trail")
 game.combat.remove_owner(b.get_instance_id())
 check(game.combat.hazards.is_empty(),"boss cleanup removes all fire")
 print("FIRE_RESULT checks=",checks," failures=",failures)
 game.queue_free();await process_frame;await create_timer(.2).timeout;quit(0 if failures.is_empty() else 1)
