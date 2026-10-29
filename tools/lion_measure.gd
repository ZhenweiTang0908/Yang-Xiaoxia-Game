extends SceneTree
# Reads the authored pose at each contact instant and reports where the paint
# actually sits relative to the actor origin, next to the configured hit cap.
const ELDER=preload("res://scripts/actors/lion_elder.gd")
var game
var boss
func _initialize():call_deferred("run")
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true
	game.start_new();await process_frame;game.jump_to_stage(5);await process_frame
	game.set_physics_process(false);game.player.set_physics_process(false);game.boss.set_physics_process(false)
	game.combat.set_physics_process(false);game.summon.set_physics_process(false)
	boss=game.boss
	for id in ELDER.CATALOG.MOVES:
		boss.phase=1 if int(id.substr(1))<=8 or id=="M19" else 2
		boss.position=Vector2(480,450);boss.facing=1;boss.active_battle=true
		boss.begin(id)
		for index in boss.beats.size():
			var beat=boss.beats[index]
			var guard=0
			while boss.t<beat.time and guard<900:boss._physics_process(1.0/240);guard+=1
			var frame=boss.visual.frame
			# Ask the shipping predicate where the paint is, so the report uses the
			# same mirroring and offset maths as real contact.
			var lo_x=999.0;var hi_x=-999.0;var lo_h=999.0;var hi_h=-999.0
			var probe=0
			for h in range(0,130,4):
				for o in range(-170,171,4):
					var world=Rect2(boss.position.x+boss.lock_dir*o-2,450-h-1,4,4)
					if boss.visual.silhouette_intersects(world,boss.position):
						probe+=1;lo_x=minf(lo_x,o);hi_x=maxf(hi_x,o);lo_h=minf(lo_h,h);hi_h=maxf(hi_h,h)
			print("MEASURE %s/%d frame=%d paint_x=[%.0f,%.0f] paint_y=[%.0f,%.0f] probes=%d cap near=%.0f far=%.0f low=%.0f high=%.0f" % [id,index,frame,lo_x,hi_x,lo_h,hi_h,probe,beat.near,beat.far,beat.low,beat.high])
	game.audio.stop_all();game.queue_free();await process_frame
	quit(0)
