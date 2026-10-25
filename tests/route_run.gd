extends SceneTree
var game
var tick=0
var durations=[]
func _initialize():call_deferred("run")
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
	var requested_stage=1
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--route-stage="):requested_stage=clampi(int(argument.get_slice("=",1)),1,3)
	if requested_stage>1:
		game.progress.bow=true;game.progress.gourd=true;game.load_stage(requested_stage,0)
	var stage_started=0
	var pending_plate=null
	while tick<70000:
		await physics_frame;tick+=1
		if game.state=="upgrade":
			var choices=game.UPGRADE_IDS;game.choose_upgrade(choices[game.progress.upgrades.size()%choices.size()])
		if game.state=="story":game.complete_story()
		if game.state=="stage_clear":
			durations.append(float(tick-stage_started)/60);print("ROUTE_STAGE ",game.level.number," seconds=",durations.back()," kills=",game.kills)
			game.next_level();stage_started=tick;await process_frame;continue
		if game.state=="win":
			durations.append(float(tick-stage_started)/60);print("ROUTE_COMPLETE assisted invulnerability; real movement and attacks; seconds=",durations," kills=",game.kills);await finish_run(0);return
		if not game.active():continue
		var p=game.player;p.invincible=999 # This is a collision/flow soak, not a difficulty or human timing test.
		var closest=null;var distance=200.0
		for e in game.enemies:
			if not is_instance_valid(e) or e.dead:continue
			if e.kind=="boss" and not e.active_battle:continue
			if absf(e.position.y-p.position.y)>100:continue
			var d=e.position.distance_to(p.position)
			if d<distance:distance=d;closest=e
		if pending_plate and pending_plate.open:pending_plate=null
		if not pending_plate:
			for gate in game.terrain.mechanisms.items:
				if gate.kind!="gate" or gate.open or gate.x<p.position.x-40 or gate.x-p.position.x>250:continue
				for plate in game.terrain.mechanisms.items:
					if plate.kind=="plate" and plate.gate==gate.x and not plate.open:pending_plate=plate;break
				if pending_plate:break
		var plate_target=pending_plate
		Input.action_release("left");Input.action_release("right");Input.action_release("down")
		if plate_target:
			var plate_x=plate_target.x+plate_target.w*.5
			if absf(plate_x-p.position.x)>8:Input.action_press("right" if plate_x>p.position.x else "left")
		elif closest:
			var dx=closest.position.x-p.position.x;p.facing=signf(dx)
			var move_threshold=15 if closest.position.y>p.position.y+45 else 42
			if absf(dx)>move_threshold:Input.action_press("right" if dx>0 else "left")
			if tick%15==0:p.enqueue("attack")
			if tick%31==0:p.enqueue("bow")
			if p.is_on_floor() and closest.position.y<p.position.y-35:p.enqueue("jump")
			if p.is_on_floor() and closest.position.y>p.position.y+45:
				Input.action_press("down");p.enqueue("jump")
		else:Input.action_press("right")
		if p.is_on_floor():
			var travel=1 if Input.is_action_pressed("right") else (-1 if Input.is_action_pressed("left") else 0)
			if travel!=0:
				var space=game.get_world_2d().direct_space_state
				var ahead=p.position+Vector2(travel*55,0)
				var ground_query=PhysicsRayQueryParameters2D.create(ahead-Vector2(0,8),ahead+Vector2(0,45),5)
				var wall_query=PhysicsRayQueryParameters2D.create(p.position-Vector2(0,24),p.position+Vector2(travel*34,-24),1)
				if not space.intersect_ray(ground_query) or space.intersect_ray(wall_query):p.enqueue("jump")
		if p.spirit>=100:p.enqueue("transform")
		if game.summon.phase=="ready":p.enqueue("summon")
		if tick%3600==0:print("ROUTE_PROGRESS stage=",game.level.number," x=",int(p.position.x)," kills=",game.kills," boss_hp=",game.boss.hp," player=",p.position," velocity=",p.velocity," foe=",closest.position if closest else Vector2.ZERO," kind=",closest.kind if closest else "none"," floor=",p.is_on_floor()," carried=",p.is_carried()," summon=",game.summon.phase," plate=",plate_target.x if plate_target else -1," left=",Input.is_action_pressed("left")," right=",Input.is_action_pressed("right")," attack=",p.attack_elapsed," dash=",p.dash_time," hitstop=",game.hitstop," collisions=",p.get_slide_collision_count())
	print("ROUTE_TIMEOUT x=",game.player.position," stage=",game.level.number);await finish_run(1)

func finish_run(code):
	game.audio.stop_all();await create_timer(.2).timeout
	game.queue_free();await process_frame;await process_frame;OS.delay_msec(100)
	quit(code)
