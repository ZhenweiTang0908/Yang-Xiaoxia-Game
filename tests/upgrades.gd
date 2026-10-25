extends SceneTree
var game
var failures=[]
var checks=0
const STORE=preload("res://scripts/core/save_store.gd")
const PATH="user://upgrades_test.json"

func _initialize():call_deferred("run")
func verify(condition,label):
	checks+=1
	if condition:print("PASS ",label)
	else:failures.append(label);push_error("FAIL "+label)
func frames(count):
	for i in count:await physics_frame
	await process_frame
func cleanup():
	for suffix in ["",STORE.TEMP_SUFFIX,STORE.BACKUP_SUFFIX]:
		var path=PATH+suffix
		if FileAccess.file_exists(path):DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
func run():
	cleanup()
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.tuning.reset();game.start_new(false)
	await frames(4)
	verify(game.progress.upgrades.is_empty() and game.progress.pending_upgrade.is_empty(),"new journey starts without martial upgrades")
	var p=game.player;p.invincible=999
	p.position.x=game.level.checkpoints[1]+5
	await frames(2)
	verify(game.state=="upgrade" and game.progress.pending_upgrade.checkpoint==1,"checkpoint pauses for a durable martial choice")
	game.hud.canvas.queue_redraw();await process_frame
	var actions=game.hud.buttons.map(func(item):return item.action)
	verify(actions.has("upgrade_blade") and actions.has("upgrade_spirit") and actions.has("upgrade_brother"),"upgrade screen exposes three choices")
	var frozen_position=p.position;var frozen_elapsed=game.elapsed
	await frames(30)
	verify(p.position==frozen_position and is_equal_approx(game.elapsed,frozen_elapsed),"martial choice freezes gameplay time and movement")
	verify(STORE.write_save(game.progress,PATH),"pending martial choice saves")
	var pending=STORE.read_save(PATH)
	verify(pending.pending_upgrade.level==1 and pending.pending_upgrade.checkpoint==1,"pending martial choice survives a round trip")
	verify(game.choose_upgrade("blade") and game.state=="playing" and game.upgrade_level("blade")==1,"blade choice resumes play and adds one stack")
	verify(game.progress.pending_upgrade.is_empty(),"completed choice clears pending state")

	var target=game.enemies.filter(func(e):return e.kind=="imp")[0]
	target.dead=false;target.hp=100;target.position=p.position+Vector2(35,0)
	p.facing=1;p.combo=1;p.sheep_time=0;game.hitstop=0;game.combat.melee(p)
	verify(is_equal_approx(target.hp,72.4),"blade stack increases real melee damage by fifteen percent")

	game.begin_upgrade(2);verify(game.choose_upgrade("spirit"),"spirit choice accepted")
	game.hitstop=0;p.spirit=100;p.enqueue("transform");await frames(2)
	verify(p.sheep() and p.sheep_time>16.9,"spirit stack extends sheep form by two seconds")
	for i in 60:
		if p.form_transition<=0:break
		await frames(1)
	game.combat.clear();p.bow_cd=0;p.enqueue("bow")
	for i in 30:
		await frames(1)
		if game.combat.shots.any(func(shot):return shot.kind=="flame"):break
	var flames=game.combat.shots.filter(func(shot):return shot.kind=="flame")
	verify(not flames.is_empty() and is_equal_approx(flames[0].damage,23*1.4+4) and p.bow_cd<.48,"spirit stack strengthens and accelerates ghost flame")

	game.begin_upgrade(2);verify(game.choose_upgrade("brother"),"brother choice accepted")
	game.progress.gourd=true;game.summon.reset(true);verify(game.summon.request(),"summon starts after brother upgrade")
	for i in 90:
		await physics_frame
		if game.summon.phase=="active":break
	verify(game.summon.phase=="active" and game.summon.remaining>33.9,"brother stack extends assist duration by four seconds")
	verify(is_equal_approx(game.summon.brother.demon_controller.cfg("demon_damage"),24.64),"brother stack increases bull rush damage by twelve percent")

	game.progress.pending_upgrade={"level":2,"checkpoint":1}
	game.load_stage(2,1)
	verify(game.state=="upgrade","loading a save restores an unresolved martial choice")
	game.choose_upgrade("blade")
	verify(STORE.write_save(game.progress,PATH),"stacked upgrades save")
	var restored=STORE.read_save(PATH)
	verify(restored.upgrades==["blade","spirit","brother","blade"] and restored.pending_upgrade.is_empty(),"upgrade order and stacks survive save round trip")

	cleanup();game.audio.stop_all();game.queue_free();await process_frame;await process_frame;await create_timer(.2).timeout;OS.delay_msec(100)
	print("UPGRADES_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
