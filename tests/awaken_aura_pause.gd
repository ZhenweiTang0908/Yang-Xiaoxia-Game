extends SceneTree
var failures=[]
var checks=0
func _initialize():call_deferred("run")
func verify(ok,label):
	checks+=1
	if not ok:failures.append(label);push_error(label)
func run():
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true
	await process_frame;await process_frame
	game.start_new(false);await process_frame
	game.process_mode=Node.PROCESS_MODE_DISABLED;game.hitstop=0
	var aura
	var backlight
	for child in game.player.get_children():
		if child.get_script()==load("res://scripts/animation/awaken_aura.gd"):aura=child
		if child.get_script()==load("res://scripts/animation/hero_backlight.gd"):backlight=child
	verify(is_instance_valid(aura) and is_instance_valid(backlight),"player aura and backlight exist")
	if not is_instance_valid(aura) or not is_instance_valid(backlight):game.queue_free();quit(1);return
	game.player.spirit=100;game.player.charge=1.1
	aura._process(.01)
	verify(game.player.ready_tint>.95,"readiness immediately turns the hero purple")
	verify(game.player.render_tint().b>game.player.render_tint().g,"readiness tint reaches the hero renderer")
	aura._process(.1)
	backlight.strength=.4
	backlight._process(.01)
	var snapshot=Vector3(aura.clock,aura.ready_age,aura.full_flash)
	var frozen_backlight=backlight.strength
	verify(snapshot.y>=.1 and snapshot.z>=.1,"active awakening and full charge effects advance")
	for state in ["paused","settings","controls","dead"]:
		game.state=state;aura._process(.5);backlight._process(.5)
		verify(Vector3(aura.clock,aura.ready_age,aura.full_flash)==snapshot,state+" freezes aura timing")
		verify(is_equal_approx(backlight.strength,frozen_backlight),state+" freezes hero backlight")
	game.state="playing";game.hitstop=.1;aura._process(.5)
	backlight._process(.5)
	verify(Vector3(aura.clock,aura.ready_age,aura.full_flash)==snapshot,"hitstop freezes aura timing")
	verify(is_equal_approx(backlight.strength,frozen_backlight),"hitstop freezes hero backlight")
	game.hitstop=0;aura._process(.1)
	backlight._process(.1)
	verify(aura.clock>snapshot.x and aura.ready_age>snapshot.y and aura.full_flash>snapshot.z,"aura resumes from its frozen phase")
	verify(not is_equal_approx(backlight.strength,frozen_backlight),"hero backlight resumes its fade")
	aura._process(1.3)
	verify(is_zero_approx(game.player.ready_tint) and aura.ready_age>1.2,"purple fades while ready wisps remain")
	game.player.spirit=0;aura._process(.01)
	verify(aura.ready_age<0 and is_zero_approx(game.player.ready_tint),"consuming readiness clears the surge")
	var atlas=load("res://scripts/actors/atlas_actor.gd")
	verify(atlas.metadata.has("res://assets/art/v3/bull.png"),"bull atlas bounds are warm before summoning")
	verify(atlas.metadata.has("res://assets/art/v2/sheep_clean.png"),"spirit atlas bounds are warm before transforming")
	game.summon.reset(true)
	verify(game.summon.request(),"first bull summon succeeds after warming")
	verify(is_instance_valid(game.summon.brother) and game.summon.brother.demon,"summon creates the current bull form")
	game.summon._physics_process(1.2)
	verify(game.summon.phase=="active" and game.summon.brother.arrived,"bull entrance completes")
	game.summon.begin_leaving();game.summon._physics_process(.8)
	verify(game.summon.phase=="cooldown","bull recall completes")
	game.queue_free();await process_frame
	print("AWAKEN_AURA_PAUSE_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
