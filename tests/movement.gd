extends SceneTree
var game
var errors=[]
func _initialize():call_deferred("run")
func frames(n):
	for i in n:await physics_frame
	await process_frame
func check(ok,label):
	print("PASS " if ok else "FAIL ",label)
	if not ok:errors.append(label)
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
	for e in game.enemies:e.set_physics_process(false);e.dead=true
	var p=game.player
	# Current authored route: low ledge -> solid roof -> upper ledge.
	# The earlier coordinates referred to terraces removed by the four-room layout.
	p.position=Vector2(2340,450);await frames(5);p.enqueue("jump");await frames(55)
	check(absf(p.position.y-370)<3,"one-way platform")
	p.position=Vector2(2350,370);p.velocity=Vector2.ZERO;await frames(4)
	Input.action_press("right");p.enqueue("jump");await frames(43);Input.action_release("right");await frames(12)
	check(absf(p.position.y-325)<3,"solid roof reachable from ledge")
	p.position=Vector2(2850,325);p.velocity=Vector2.ZERO;await frames(4)
	Input.action_press("right");p.enqueue("jump");await frames(44);Input.action_release("right");await frames(12)
	check(absf(p.position.y-240)<3,"upper roof ledge reachable")
	# A real solid vertical wall must stop the native player body.
	var wall=StaticBody2D.new();var c=CollisionShape2D.new();var shape=RectangleShape2D.new();shape.size=Vector2(20,160);c.shape=shape;wall.add_child(c);wall.position=Vector2(1900,370);game.world.add_child(wall)
	p.position=Vector2(1850,450);p.velocity=Vector2.ZERO;await frames(4);Input.action_press("right");await frames(40);Input.action_release("right")
	check(p.position.x<1884,"solid wall blocks player");wall.queue_free()
	# Reachability graph for every authored terrace. Ballistic jump roots include a 12px horizontal safety margin.
	for stage in [1,2,3]:
		var level=load("res://data/levels/level_"+str(stage)+".tres");var reached={}
		for i in level.platforms.size():
			if not level.platforms[i].one_way:reached[i]=true
		for iteration in 10:
			for i in level.platforms.size():
				if reached.has(i):continue
				var b=level.platforms[i]
				for j in reached.keys():
					var a=level.platforms[j];var height=a.y-b.y;var disc=520.0*520-2*1080*height
					if disc<0:continue
					var duration=(520+sqrt(disc))/1080
					var gap=maxf(0,maxf(b.x-a.x-a.w,a.x-b.x-b.w))
					if gap+12<225*duration:reached[i]=true;break
		check(reached.size()==level.platforms.size(),"every terrace reachable level "+str(stage))
	print("MOVEMENT_RESULT failures=",errors)
	game.audio.stop_all();await create_timer(.1).timeout;game.free();quit(0 if errors.is_empty() else 1)
