extends SceneTree
const SOUND=preload("res://scripts/combat/enemy_audio.gd")
var game
var failures=[]
var checks=0
func _initialize():call_deferred("run")
func verify(ok,label):
	checks+=1
	if ok:print("PASS ",label)
	else:failures.append(label);push_error(label)
func quiet_stage():
	game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false);game.combat.set_physics_process(false)
	for enemy in game.enemies:enemy.set_physics_process(false)
func reset_feedback():
	game.state="playing";game.hitstop=0;game.combat.clear();game.fx.clear();game.audio.enemy_history.clear();game.audio.enemy_recent.clear()
	game.player.health=100;game.player.invincible=0;game.player.hurt_anim=0;game.player.position=Vector2(600,450)
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.start_new(false);quiet_stage();await process_frame
	verify(SOUND.CATALOG.PROFILES.size()==28,"all eight mobs and twenty boss moves have identities")
	var sounds={};var all_valid=true
	for profile in SOUND.CATALOG.PROFILES.values():
		for stage in ["warning","release","impact"]:
			var key=profile[stage];var stream=game.audio.bank.get(key)
			all_valid=all_valid and stream!=null and stream.get_length()>=.2 and stream.get_length()<=.7
			if stream!=null:sounds[hash(stream.data)]=true
	verify(all_valid and sounds.size()==84,"84 distinct playable Foley cues with bounded duration")
	var enemy=game.enemies[0]
	for kind in SOUND.MOB_MOVES:
		reset_feedback();enemy.dead=false;enemy.kind=kind;enemy.position=Vector2(500,450);enemy.target=game.player.position;enemy.facing=1
		enemy.release_attack()
		var identity=kind+":"+SOUND.MOB_MOVES[kind]
		verify(game.audio.enemy_history.has(SOUND.CATALOG.PROFILES[identity].release),kind+" releases its own attack sound")
		verify((game.combat.shots+game.combat.hazards).all(func(attack):return attack.attack_sound==identity),kind+" attacks keep their sound identity")
	for stage in [1,2,3]:
		game.load_stage(stage,0);quiet_stage();await process_frame
		var boss=game.boss;boss.active_battle=true
		for i in boss.spec.moves.size():
			reset_feedback();boss.events.clear();boss.start_move(i);boss.release_move()
			for event in boss.events.duplicate():boss.execute_event(event.type,event.payload)
			var identity=boss.spec.id+":"+boss.move.id;var profile=SOUND.CATALOG.PROFILES[identity]
			verify(game.audio.enemy_history.has(profile.warning) and game.audio.enemy_history.has(profile.release),identity+" has matching warning and release")
			verify((game.combat.shots+game.combat.hazards).all(func(attack):return attack.attack_sound==identity),identity+" tags delayed/projectile attacks")
	var boss=game.boss
	reset_feedback();boss.start_move(4);boss.release_move();var shot=game.combat.shots[0]
	boss.start_move(5)
	verify(shot.attack_sound=="priest:ring","ring bullets retain their identity after switching to homing")
	reset_feedback();boss.start_move(3);boss.execute_event("lightning",{"damage":24});var zone=game.combat.hazards[0];boss.start_move(6)
	verify(zone.attack_sound=="priest:lightning","delayed lightning retains identity after switching to beam")
	reset_feedback();var p=game.player
	game.combat.fire(p.position-Vector2(0,21),Vector2.RIGHT,12,"enemy","dart",{"attack_sound":"dart:dart"});game.combat._physics_process(.01)
	verify(p.health==88 and game.audio.enemy_history.has(SOUND.CATALOG.PROFILES["dart:dart"].impact),"real dart damage plays dart-specific body impact")
	verify(game.fx.hit_marks.size()==1 and p.hurt_anim>0 and game.hitstop>=.06,"actual damage produces one visible impact and hitstop")
	p.skeletal_visual.painted_motion._physics_process(.016)
	verify(p.skeletal_visual.painted_motion.rig.action_state=="hurt","hurt pose appears immediately during damage hitstop")
	reset_feedback();p.invincible=.5
	game.combat.fire(p.position-Vector2(0,21),Vector2.RIGHT,12,"enemy","dart",{"attack_sound":"dart:dart"});game.combat._physics_process(.01)
	verify(p.health==100 and game.fx.hit_marks.is_empty() and game.audio.enemy_history.is_empty(),"invulnerability produces no false injury sound or flash")
	reset_feedback();var hazard=game.combat.hazard(Rect2(p.position-Vector2(25,38),Vector2(50,38)),0,.2,17,0,"binding_rune");hazard.attack_sound="shaman:rune";game.combat._physics_process(.01)
	verify(p.health==83 and game.audio.enemy_history.has(SOUND.CATALOG.PROFILES["shaman:rune"].impact),"rune hazard delivers its own actual-hit sound")
	reset_feedback()
	for i in 12:game.audio.enemy_cue("priest:rain","release")
	verify(game.audio.enemy_history.size()==1,"overlapping rain sectors are rate limited")
	for identity in SOUND.CATALOG.PROFILES:game.audio.enemy_cue(identity,"release")
	game.audio.enemy_cue("guardian:sweep","impact")
	verify(game.audio.hurt_players.any(func(voice):return voice.playing and voice.stream==game.audio.bank[SOUND.CATALOG.PROFILES["guardian:sweep"].impact]),"injury sound uses reserved voices during a crowded battle")
	verify(game.audio.impact_duck>=5,"actual hit temporarily ducks music")
	reset_feedback();enemy=game.enemies[0];enemy.dead=false;enemy.kind="imp";enemy.hp=100;enemy.windup=.5
	enemy.take_hit(10,"player",1,false,false,false)
	verify(enemy.windup==.5 and enemy.art.tint.r>1.5 and enemy.art.position.x>0,"enemy flashes and recoils immediately without erasing its warning")
	game.state="paused";var mark=game.fx.hit_marks[0].duplicate();game.fx._process(.2)
	verify(game.fx.hit_marks[0]==mark,"pause freezes impact marks")
	game.audio.stop_all();game.queue_free();await process_frame;await process_frame;await create_timer(.2).timeout
	print("COMBAT_IMPACT_AUDIO_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
