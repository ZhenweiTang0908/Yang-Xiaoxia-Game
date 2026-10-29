extends SceneTree
# Slow manual audit: for every contact beat, sweep stances inside arm's reach and
# report the ones that are completely covered. A beat with no safe stance in that
# window has no reaction answer beyond running away from the arena.
# Run: .agents/skills/godot-headless-test/run_test.sh tools/lion_stance_audit.gd 900
const ELDER=preload("res://scripts/actors/lion_elder.gd")
var game
var boss
var covered=[]
func _initialize():call_deferred("run")
func reset(id,face):
	game.state="playing";game.hitstop=0;game.player.health=100;game.player.invincible=0
	game.progress["journey_mode"]="standard"
	game.player.position=Vector2(900,450);boss.position=Vector2(400,450);boss.facing=face
	boss.phase=1 if int(id.substr(1))<=8 or id=="M19" else 2
	boss.phase_shift=0;boss.stagger_left=0;boss.stagger_kind="";boss.whiff_ready=0
	boss.turn_left=0;boss.dead=false;boss.hp=boss.max_hp;boss.active_battle=true;boss.begin(id)
func advance_to(at):
	var guard=0
	while boss.t<at-.0000001 and boss.action!="" and guard<4000:
		game.hitstop=0;boss._physics_process(minf(1.0/240,at-boss.t));guard+=1
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true
	game.start_new();await process_frame;game.jump_to_stage(5);await process_frame
	boss=game.boss
	game.set_physics_process(false);game.player.set_physics_process(false);boss.set_physics_process(false)
	game.combat.set_physics_process(false);game.summon.set_physics_process(false)
	var beats=0
	for id in ELDER.CATALOG.MOVES:
		for face in [-1.0,1.0]:
			for index in ELDER.CATALOG.MOVES[id].beats.size():
				beats+=1
				reset(id,face);advance_to(boss.beats[index].time)
				var cap=boss.beat_rect(index,boss.position.x,boss.position.x)
				var safe_within=0;var hits=0;var samples=0
				for height in range(0,124,12):
					for offset in range(-120,121,12):
						if safe_within>0:break
						samples+=1
						var rect=Rect2(boss.position.x+boss.lock_dir*offset-8,450-height-38,16,38)
						var overlap=cap.intersection(rect)
						if overlap.has_area() and boss.visual.silhouette_intersects(overlap,boss.position):hits+=1
						else:safe_within+=1
					if safe_within>0:break
				if safe_within==0:
					covered.append("%s/%d face=%s" % [id,index,face])
					print("NO_SAFE_STANCE ",id,"/",index," face=",face," hits=",hits,"/",samples)
	print("LION_STANCE_AUDIT beats=",beats," covered=",covered.size())
	quit(0 if covered.is_empty() else 1)
