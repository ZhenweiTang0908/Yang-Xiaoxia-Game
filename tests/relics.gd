extends SceneTree
var game
var failures=[]
var checks=0
const STORE=preload("res://scripts/core/save_store.gd")
const PATH="user://relics_test.json"

func _initialize():call_deferred("run")
func verify(condition,label):
	checks+=1
	if condition:print("PASS ",label)
	else:failures.append(label);push_error("FAIL "+label)
func cleanup():
	for suffix in ["",STORE.TEMP_SUFFIX,STORE.BACKUP_SUFFIX]:
		var path=PATH+suffix
		if FileAccess.file_exists(path):DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
func run():
	cleanup()
	var authored=[]
	for number in [1,2,3]:
		var stage=load("res://data/levels/level_"+str(number)+".tres")
		var stage_relics=stage.pickups.filter(func(item):return item.kind=="relic")
		verify(stage_relics.size()==2,"stage "+str(number)+" has two moon relics")
		for item in stage_relics:authored.append(item.id)
	verify(authored.size()==6 and authored.all(func(id):return id in game_ids()),"six authored relic ids match the collection catalog")
	verify(authored.duplicate().reduce(func(unique,id):return unique if id in unique else unique+[id],[]).size()==6,"moon relic ids are unique")

	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=STORE.defaults();game.start_new(false);await process_frame
	verify(game.relic_count()==0,"old and new saves begin with an empty collection")
	var first=game.pickups.filter(func(item):return item.kind=="relic")[0]
	game.player.spirit=0;game.player.position=Vector2(first.x,first.y+20);game._physics_process(1.0/60.0)
	verify(first.taken and game.relic_count()==1,"touching a relic collects it")
	verify(game.player.spirit==15 and game.hint=="获得月痕","first collection grants awakening and a concise notice")
	verify(not game.collect_relic(first.id) and game.relic_count()==1,"duplicate collection is rejected")
	var second=game.pickups.filter(func(item):return item.kind=="relic" and not item.taken)[0]
	game.player.spirit=95;verify(game.collect_relic(second.id) and game.player.spirit==100,"relic awakening reward respects its cap")
	verify(STORE.write_save(game.progress,PATH),"relic collection saves")
	var restored=STORE.read_save(PATH)
	verify(restored.relics.size()==2,"relic collection survives a save round trip")
	game.load_stage(1,0)
	verify(game.pickups.filter(func(item):return item.kind=="relic").all(func(item):return item.taken),"collected relics stay absent after stage reload")
	game.start_new(false)
	verify(game.relic_count()==2 and game.progress.upgrades.is_empty(),"new journey preserves relics while resetting martial upgrades")
	cleanup();game.audio.stop_all();game.queue_free();await process_frame;await process_frame;await create_timer(.2).timeout;OS.delay_msec(100)
	print("RELICS_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
func game_ids():return ["moon_1_roof","moon_1_seal","moon_2_roof","moon_2_seal","moon_3_roof","moon_3_seal"]
