extends SceneTree
var game
var failures=[]
var checks=0
func _initialize():call_deferred("run")
func verify(ok,label):
	checks+=1
	if ok:print("PASS ",label)
	else:failures.append(label);push_error("FAIL "+label)
func pose(k,id,at):
	k.action="";k.dismount_t=-1;k.visual.held_action=""
	k.begin(id,k.prep_for(id));k.t=at;k.visual.sync_pose(0)
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true
	game.start_new(false);await process_frame;game.start_challenge();await process_frame
	var k=game.boss;k.active_battle=true;k.set_physics_process(false)
	game.player.set_physics_process(false);game.combat.set_physics_process(false)
	var v=k.visual
	for pair in [["foot",v.foot],["mounted",v.mounted],["extra",v.extra],["pressure",v.pressure]]:
		var name=pair[0];var art=pair[1]
		verify(art.isolated.size()==12,name+" has twelve isolated painted key poses")
		verify(art.get_script().get_base_script().resource_path=="res://scripts/animation/actor_pose_art.gd",name+" uses the original boss 2D mesh renderer")
		for i in 12:
			var img=art.isolated[i].get_image()
			verify(not img.get_used_rect().has_point(Vector2i.ZERO) and img.get_used_rect().get_area()>100,name+" pose "+str(i)+" has real transparency and visible artwork")
	var queue=[v];var uses_3d=false
	while not queue.is_empty():
		var node=queue.pop_back();uses_3d=uses_3d or node is SubViewport or node is Node3D
		queue.append_array(node.get_children())
	verify(not uses_3d,"knight has no Blender/3D/SubViewport runtime dependency")
	k.phase=2;k.landed=true;k.weapon="spear"
	pose(k,"wave",.15);verify(v.selected==v.foot and v.selected_frame==1,"spear wave visibly raises the arm first")
	pose(k,"wave",.30);verify(v.selected_frame==2,"spear wave has a separate shoulder-back draw")
	pose(k,"wave",.42);verify(v.selected_frame==3 and v.foot.bridge_left==0,"the actual wave hit displays the committed thrust immediately")
	var tip=v.foot_socket(3,"spear_tip")
	verify(tip.y>=-12 and tip.y<=1,"painted spear tip aligns with the low pressure band: "+str(tip))
	k.wave_uses=1;pose(k,"wave",2.8)
	verify(v.selected_frame==0,"delayed third waits in regrip rather than hiding a shot")
	k.wave_uses=1;pose(k,"wave",3.27)
	verify(v.selected_frame==1,"delayed third retains the full raised-arm warning")
	pose(k,"thrust",.45);verify(v.selected_frame==5,"normal thrust has its own hero-height contact pose")
	k.finish(.6);v.sync_pose(1.0/60)
	verify(v.current=="thrust" and v.selected_frame==5,"recovery preserves the committed attack pose")
	k.weapon="bow";pose(k,"bow",.60)
	verify(v.selected_frame==6,"bow telegraph uses a fully drawn painted bowstring")
	var origin=k.bow_origin()
	verify(origin.distance_to(k.position+v.foot_socket(7,"bow"))<.1,"aim and projectile share the painted release socket")
	pose(k,"bow",.71);verify(v.selected_frame==7,"release switches to an empty-string bow pose")
	k.weapon="spear";pose(k,"spin_rush",.3);verify(v.selected==v.pressure and v.selected_frame==0,"spin rush has a distinct coiled shoulder tell")
	pose(k,"spin_rush",.8);verify(v.selected==v.pressure and v.selected_frame in [2,3,4],"spin rush cycles authored spinning spear silhouettes")
	pose(k,"spear_return",.8);verify(v.selected==v.pressure and v.selected_frame==6,"thrown lance leaves both hands empty")
	k.phase=1;k.landed=false;k.weapon="spear";pose(k,"charge",.7);k.fired.run=true;v.sync_pose(0)
	verify(v.selected==v.mounted and v.selected_frame in [3,4,5,6],"mounted charge cycles authored four-beat gallop poses")
	k.action="";k.begin_dismount();k.dismount_t=.55;v.sync_pose(0)
	verify(v.selected==v.extra and v.selected_frame==6 and v.horse.visible and not v.mounted.visible,"dismount separates the airborne knight from the empty saddle")
	k.land();k.dismount_t=1.0;v.sync_pose(0)
	verify(v.selected_frame==7,"landing shows a dedicated crouch before standing")
	k.dismount_t=-1;k.horse_away=2;k.action="";v.held_action="";v.sync_pose(0)
	verify(v.selected==v.foot and not v.horse.visible,"foot combat leaves no stale mounted silhouette")
	game.hitstop=0;game.state="playing";game.player.position=Vector2(200,450);game.player.invincible=0;game.player.health=100
	game.audio.enemy_history.clear();k.fire_wave()
	verify("knight_hit_wave" in game.audio.enemy_history,"actual wave contact has its dedicated physical hit sound")
	game.hitstop=0;game.player.position.y=420;game.player.invincible=0
	game.audio.enemy_history.clear();game.audio.enemy_recent.clear();k.fire_wave()
	verify(not "knight_hit_wave" in game.audio.enemy_history,"a jumped-over wave has no false body impact")
	game.audio.stop_all();game.queue_free();await process_frame
	print("KNIGHT_PAINTED checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
