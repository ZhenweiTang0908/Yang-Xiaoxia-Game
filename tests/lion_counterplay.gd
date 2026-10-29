extends SceneTree
# Taking a hit during the first beat of a multi-beat move must not cancel the later
# beats, otherwise the combo silently becomes a single swing. The exhaustive
# "is there a safe stance inside arm's reach" sampling lives in
# tools/lion_stance_audit.gd because it is too slow for the regular suite.
const ELDER=preload("res://scripts/actors/lion_elder.gd")
const MULTI=["M08","M12","M17","M18","M19","M20"]
var game
var boss
var checks=0
var failures=[]
func _initialize():call_deferred("run")
func verify(ok,label):
	checks+=1
	if not ok:failures.append(label);push_error("FAIL "+label)
func reset(id,face=1.0):
	game.state="playing";game.hitstop=0;game.player.health=100;game.player.invincible=0;game.player.roll_guard=0
	game.progress["journey_mode"]="standard"
	game.player.position=Vector2(900,450);boss.position=Vector2(400,450);boss.facing=face
	boss.phase=1 if int(id.substr(1))<=8 or id=="M19" else 2
	boss.phase_shift=0;boss.stagger_left=0;boss.stagger_kind="";boss.whiff_ready=0
	boss.turn_left=0;boss.dead=false;boss.hp=boss.max_hp;boss.active_battle=true;boss.damage_log.clear()
	boss.begin(id)
func advance_to(at):
	var guard=0
	while boss.t<at-.0000001 and boss.action!="" and guard<4000:
		game.hitstop=0
		boss._physics_process(minf(1.0/240,at-boss.t));guard+=1
func hurt_rect(x,height):return Rect2(x-8,450-height-38,16,38)
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true
	game.start_new();await process_frame;game.jump_to_stage(5);await process_frame
	boss=game.boss
	game.set_physics_process(false);game.player.set_physics_process(false);boss.set_physics_process(false)
	game.combat.set_physics_process(false);game.summon.set_physics_process(false)
	# Later beats must survive damage taken during the first one.
	for id in MULTI:
		if ELDER.CATALOG.MOVES[id].beats.size()<2:continue
		reset(id);advance_to(boss.beats[0].time+.001)
		game.player.position=Vector2(boss.position.x+boss.lock_dir*60,450)
		boss.take_hit(5,"player",1,false,false,false)
		verify(boss.action==id and boss.beats.size()>=2,"first hit keeps later beats %s action=%s" % [id,boss.action])
		var later=boss.beats[1].time;advance_to(later+boss.beats[1].window+.01)
		verify(boss.damage_log.size()>=1 or boss.t>later,"combo still advances after early hit "+id)
	game.audio.stop_all();game.queue_free();await process_frame
	print("LION_COUNTERPLAY_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
