extends SceneTree
var failures=[]
var checks=0
var game

func _initialize():call_deferred("run")
func verify(condition,label):
	checks+=1
	if condition:print("PASS ",label)
	else:failures.append(label);push_error("FAIL "+label)
func begin_roll(player):
	game.hitstop=0
	player.dash_time=0;player.dash_cd=0;player.roll_guard=0;player.invincible=0;player.enqueue("dash");player._physics_process(.01)
func projectile_hit(player,kind="dart"):
	game.combat.fire(player.position-Vector2(0,21),Vector2.RIGHT,20,"enemy",kind);game.combat._physics_process(.01)
func hazard_hit(player,kind="sweep"):
	game.combat.hazard(Rect2(player.position-Vector2(20,48),Vector2(40,52)),0,.2,20,99,kind);game.combat._physics_process(.01)
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.start_new(false);await process_frame
	var p=game.player;p.health=100;p.rage=0;p.spirit=0
	p.invincible=.5;p.roll_guard=0;p.take_damage(20,0,"dart")
	verify(p.health==100 and p.rage==0 and p.spirit==0,"ordinary invulnerability gives no precision reward")
	p.invincible=0;p.dash_cd=0;p.enqueue("sprint");p._physics_process(.01);p.take_damage(20,0,"dart")
	verify(p.sprinting and p.health==80 and p.rage==0,"forward sprint is not mistaken for a dodge")
	p.health=100;p.rage=0;p.spirit=0;begin_roll(p)
	verify(p.roll_guard>0 and p.invincible>0 and not p.sprinting,"roll opens a dedicated precision window")
	p.take_damage(18,0,"fall")
	verify(p.rage==0 and p.spirit==0 and not p.dodge_rewarded,"fall recovery cannot masquerade as an enemy dodge")
	projectile_hit(p)
	verify(p.health==100 and p.rage==15 and p.spirit==12 and p.dodge_flash>0,"real projectile intersection triggers one perfect dodge")
	verify("战意 +15" in p.dodge_message and "觉醒 +12" in p.dodge_message,"HUD message reports actual gains")
	projectile_hit(p,"orb")
	verify(p.rage==15 and p.spirit==12,"multiple attacks in one roll reward only once")
	begin_roll(p);hazard_hit(p)
	verify(p.rage>29.9 and p.spirit==24,"a later roll can reward a real hazard intersection")
	p.rage=95;p.spirit=96;begin_roll(p);hazard_hit(p,"binding_rune")
	verify(p.rage==100 and p.spirit==100 and "战意 +5" in p.dodge_message and "觉醒 +4" in p.dodge_message,"reward respects caps and reports truncated gains")
	var flash=p.dodge_flash;game.state="paused";p._physics_process(.4)
	verify(is_equal_approx(p.dodge_flash,flash),"pause freezes perfect dodge feedback")
	game.state="playing";game.progress.journey_mode="relaxed";p.health=100;p.rage=0;p.spirit=0;begin_roll(p);projectile_hit(p)
	verify(p.health==100 and p.rage==15 and p.spirit==12,"journey strength does not alter perfect dodge rewards")
	p.reset(Vector2(100,450),false)
	verify(p.roll_guard==0 and not p.dodge_rewarded and p.dodge_flash==0 and p.dodge_message.is_empty(),"checkpoint reset clears transient dodge state")
	game.audio.stop_all();game.queue_free();await process_frame;await process_frame;await create_timer(.2).timeout;OS.delay_msec(100)
	print("PERFECT_DODGE_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
