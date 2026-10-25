extends SceneTree
var game
var failures=[]
var checks=0
const FEATURES=preload("res://scripts/world/room_features.gd")

func _initialize():call_deferred("run")
func verify(condition,label):
	checks+=1
	if condition:print("PASS ",label)
	else:failures.append(label);push_error("FAIL "+label)
func feature_node():
	for child in game.terrain.get_children():
		if child.get_script() and child.get_script().resource_path.ends_with("room_features.gd"):return child
	return null
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true
	game.load_stage(1,0)
	verify(game.level.features.all(func(item):return item.kind not in ["gust","ritual"]),"stage one keeps clear tutorial spaces")
	game.load_stage(2,0)
	var features=feature_node();var gusts=features.items.filter(func(item):return item.kind=="gust")
	verify(gusts.size()==2,"stage two owns two mist currents")
	var gust=gusts[0];game.player.position=Vector2(gust.x+gust.w*.5,gust.y+gust.h*.5);game.player.environment_force=0
	features._physics_process(1.0/60.0)
	verify(is_equal_approx(game.player.environment_force,gust.force),"mist current applies authored horizontal force")
	var start_x=game.player.position.x;Input.action_press("right")
	for frame in 20:await physics_frame
	Input.action_release("right")
	verify(game.player.position.x>start_x+20,"player can advance against a mist current")
	game.load_stage(3,0)
	features=feature_node();var rituals=features.items.filter(func(item):return item.kind=="ritual")
	verify(rituals.size()==3,"stage three owns three ritual fields")
	var warning=FEATURES.ritual_state(3.0,3.8,.0)
	var active=FEATURES.ritual_state(3.6,3.8,.0)
	verify(warning.warning and not warning.active and active.active,"ritual warning precedes active pulse")
	var ritual=rituals[0];game.player.position=Vector2(ritual.x,ritual.y);game.player.health=100;game.player.invincible=0
	features.clock=ritual.period-ritual.get("phase",0.0)-.2
	features._physics_process(.01)
	verify(game.player.health<100,"active ritual damages a player who remains inside")
	var frozen=features.clock;game.state="paused";features._physics_process(1.0)
	verify(is_equal_approx(features.clock,frozen),"environment cycles freeze while paused")
	game.audio.stop_all();await create_timer(.2).timeout
	game.queue_free();await process_frame;await process_frame;OS.delay_msec(100)
	print("LEVEL_IDENTITY_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
