extends SceneTree
var game
var failed=0
func check(ok,label):
 if not ok:failed+=1;push_error(label)
 else:print("PASS ",label)
func _initialize():call_deferred("run")
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 for e in game.enemies:e.set_physics_process(false)
 game.player.set_physics_process(false);game.player.position=Vector2(200,450);game.player.health=100
 game.combat.set_physics_process(false)
 var c=game.combat
 for kind in ["fire","breath","spirit_beam","stone_wave","stone_impact","antler_sweep","blade_sweep","spectral_horn","rift","ground_rift","spirit_lightning","ritual","binding_rune","pounce_impact"]:
  c.clear();c.hazard(Rect2(1000,400,90,50),.1,.2,20,42,kind)
  c._physics_process(.05);check(c.hazards[0].age==0,"warning does not spend active life: "+kind)
  c._physics_process(.06);c._physics_process(.1);check(c.hazards.size()==1,"active hazard persists: "+kind)
  c._physics_process(.11);check(c.hazards.is_empty() and c.remnants.size()==1,"damage ends before visual remnant: "+kind)
  game.player.position=Vector2(1030,450);game.player.invincible=0;c._physics_process(.1)
  check(game.player.health==100,"remnant is harmless: "+kind)
  c.remove_owner(42);check(c.remnants.is_empty(),"owner cleanup clears remnant: "+kind)
  game.player.position=Vector2(200,450)
 c.clear();game.player.position=Vector2(1030,450);game.player.health=100;game.player.invincible=0
 var rain=c.hazard(Rect2(1020,100,25,350),0,.2,24,42,"rain")
 c._physics_process(.01);check(game.player.health==100,"falling blade cannot hit ground before reaching it")
 c._physics_process(.12);check(game.player.health==76,"falling blade damages at visible ground arrival")
 game.player.invincible=0;c._physics_process(.02);check(game.player.health==76,"one blade only hits once")
 c.clear();game.player.health=100;game.player.position=Vector2(200,450)
 for i in 40:game.fx.impact(Vector2(200,420),"card",Vector2.RIGHT)
 check(game.fx.impacts.size()==24,"impact effect count capped")
 game.fx.set_process(false);game.state="paused";var age=game.fx.impacts[0].age;game.fx._process(.1)
 check(game.fx.impacts[0].age==age,"pause freezes semantic impacts")
 game.state="playing";c.clear();game.fx.clear();check(game.fx.impacts.is_empty(),"stage cleanup removes impacts")
 game.audio.stop_all();game.queue_free();await process_frame;print("SKILL_LIFECYCLE failures=",failed);quit(failed)
