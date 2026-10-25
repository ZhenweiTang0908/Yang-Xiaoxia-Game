extends SceneTree
var game
var failures=[]
var checks=0

func _initialize():call_deferred("run")
func verify(condition,label):
	checks+=1
	if condition:print("PASS ",label)
	else:failures.append(label);push_error("FAIL "+label)
func section_enemies(section):
	return game.enemies.filter(func(enemy):return enemy.kind!="boss" and enemy.section==section)
func clear_except_last(section):
	var group=section_enemies(section)
	for i in group.size()-1:group[i].dead=true
	return group.back()
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
	await physics_frame;await process_frame
	for enemy in game.enemies:enemy.set_physics_process(false)
	var first_group=section_enemies(0)
	verify(first_group.size()==8,"first section exposes its authored enemy count")
	game.player.health=50;game.player.spirit=0
	first_group[0].dead=true
	verify(not game.on_enemy_defeated(first_group[0]) and game.player.health==50,"partial clear grants no reward")
	for enemy in first_group:enemy.dead=true
	verify(game.on_enemy_defeated(first_group.back()),"last enemy completes the section")
	verify(game.player.health==62 and game.player.spirit==20,"section clear restores health and awakening")
	var first_state=game.section_progress(0)
	verify(first_state.cleared and first_state.defeated==first_state.total,"section progress reports a completed clear")
	game.player.health=40;game.player.spirit=0
	verify(not game.on_enemy_defeated(first_group.back()) and game.player.health==40,"section reward triggers only once per load")

	var ally_target=clear_except_last(1)
	game.player.health=95;game.player.spirit=90;ally_target.dead=false;ally_target.hp=1
	ally_target.take_hit(2,"brother",1)
	verify(ally_target.dead and game.section_progress(1).cleared,"brother finishing blow can complete a section")
	verify(game.player.health==100 and game.player.spirit==100,"section reward respects resource caps")

	game.load_stage(2,0)
	verify(game.section_clears.is_empty() and not game.section_progress(0).cleared,"loading a stage resets transient clear claims")
	game.audio.stop_all();game.queue_free();await process_frame;await process_frame;await create_timer(.2).timeout;OS.delay_msec(100)
	print("SECTION_CLEAR_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
