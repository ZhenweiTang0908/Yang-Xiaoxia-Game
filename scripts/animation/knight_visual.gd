extends Node2D
# Same painted PNG + 2D mesh pose technology as the three original bosses.
const ART=preload("res://scripts/animation/knight/painted_art.gd")
const FEEDBACK=preload("res://scripts/combat/hit_feedback.gd")
var actor
var foot
var mounted
var extra
var horse
var arsenal
var mounted_arsenal
var pressure
var current="idle"
var sample_time=0.0
var held_action=""
var held_time=0.0
var recovery_age=0.0
var was_action=""
var selected
var selected_frame=0
# Measured sockets in the isolated painted frames. X values below are source
# pixels in the original atlas, converted through support-foot anchors.
const FOOT_SOCKETS={
 3:{"spear_tip":Vector2(1029,364),"hand":Vector2(1195,273)},
 5:{"spear_tip":Vector2(337,539),"hand":Vector2(514,550)},
 6:{"bow":Vector2(803,503)},
 7:{"bow":Vector2(1196,511)},
 8:{"blade_tip":Vector2(316,977),"blade_base":Vector2(231,891)},
 9:{"blade_tip":Vector2(679,796),"blade_base":Vector2(514,744)},
 10:{"blade_tip":Vector2(665,1016),"blade_base":Vector2(801,907)}
}
const ARSENAL_SOCKETS={
 8:{"bow":Vector2(106,860)},
 9:{"blade_tip":Vector2(679,875),"blade_base":Vector2(537,808)},
 10:{"blade_tip":Vector2(710,918),"blade_base":Vector2(850,909)},
 11:{"blade_tip":Vector2(1140,773),"blade_base":Vector2(1300,899)}
}
func _ready():
	foot=make_art("foot",106.0/222.0,106);foot.lower_weapon=true
	mounted=make_art("mounted",148.0/241.0,148)
	extra=make_art("extra",106.0/191.0,106)
	horse=make_art("extra",110.0/197.0,110);horse.z_index=-1
	arsenal=make_art("arsenal",106.0/210.0,106);arsenal.lower_weapon=true
	pressure=make_art("pressure",106.0/225.0,106)
	mounted_arsenal=make_art("arsenal",148.0/280.0,148)
	sync_pose(0)
func make_art(bank,unit,height):
	var art=ART.new();art.actor=actor;add_child(art)
	art.setup("res://assets/art/knight_frames/"+bank,unit,height)
	return art
func show_art(art,index,offset=Vector2.ZERO,contact=false):
	selected=art;selected_frame=index
	art.visible=true;art.frame=index;art.facing=-actor.facing
	art.position=offset+Vector2(0,art.ground_offset())
	art.lean=0;art.sink=0
	art.prepare(index)
	if contact:art.snap_pose()
func wave_frame(at):
	var frame=0
	for release in actor.wave_times:
		if at<release-.42:continue
		var before=release-at
		if before>.22:frame=1
		elif before>.055:frame=2
		elif before>-.20:frame=3
		elif before>-.36:frame=2
		else:frame=0
	return frame
func foot_pose(action,at):
	var prep=actor.prep_for(action)
	match action:
		"wave":return wave_frame(at)
		"thrust","counter":return 4 if at<prep-.045 else (5 if at<prep+.25 else (4 if at<prep+.42 else 0))
		"butt_spin":return 2 if at<.46 else (11 if at<.75 else 0)
		"guard":return 11
		"bow":return 7 if actor.bow_releasing(at) else 6
		"switch":return 11 if at<.25 else 0
	return 0
func gallop_frame(stride):
	var u=fposmod(stride/TAU,1.0)
	return 3 if u<.22 else (4 if u<.41 else (5 if u<.65 else 6))
func sync_pose(dt):
	if not is_instance_valid(actor):return
	var a=actor
	for art in [foot,mounted,extra,horse,arsenal,mounted_arsenal,pressure]:art.hide();art.advance(dt)
	var action=a.action;var at=a.t
	if action!="":held_action=action;held_time=at;recovery_age=0
	elif held_action!="":
		recovery_age+=dt;action=held_action;at=held_time+recovery_age
		if recovery_age>.65:held_action="";action=""
	current=action if action!="" else "idle";sample_time=at
	if a.dead:
		show_art(extra,11,Vector2.ZERO,true);held_action=""
	elif a.dismount_t>=0:
		dismount_pose()
	elif a.action=="ancient_spear":
		show_art(pressure,11 if at<.65 else 6,Vector2.ZERO,at>=.65)
		selected.lean=-.035 if at<.65 else .02
		if a.phase==1:
			horse.visible=true;horse.frame=0;horse.facing=-a.facing;horse.prepare(0)
			horse.position=Vector2(a.flight_from.x-a.position.x,a.GROUND-a.position.y+horse.ground_offset())
	elif a.phase==1:
		var index=0
		match action:
			"charge","rein":
				var prep=a.prep_for(action)
				if a.t<prep:index=0 if a.t<prep*.25 else (1 if a.t<prep*.70 else 2)
				elif not a.fired.has("stop"):index=gallop_frame(a.stride)
				else:index=2
			"soul_legion":index=7 if at<.9 else 0
			"rear":index=7 if at<a.prep_for("rear") else 0
			"kick":index=8 if at<a.prep_for("kick") else (9 if at<a.prep_for("kick")+.22 else 0)
			"butt":index=10 if at<a.prep_for("butt") else (11 if at<a.prep_for("butt")+.25 else 0)
		if action=="advance":
			var relative=at-a.prep_for(action)
			var beat=fposmod(relative,a.ADVANCE_GAP)
			var contact=relative>=0 and relative<=2*a.ADVANCE_GAP+.18 and beat<.18
			show_art(mounted_arsenal,1 if contact else 0,Vector2.ZERO,contact)
		elif action=="uppercut":show_art(mounted_arsenal,2 if at<a.prep_for(action) else 3,Vector2.ZERO,at>=a.prep_for(action))
		else:show_art(mounted,index,Vector2.ZERO,index in [3,4,5,6,9,11])
	else:
		departing_horse()
		if action=="soul_legion":show_art(pressure,11 if at<.9 else 0)
		elif action=="stagger":show_art(extra,11,Vector2.ZERO,true)
		elif action in a.SPEAR.MOVES:meteor_pose(action,at)
		elif action in a.PRESSURE_MOVES:pressure_pose(action,at)
		elif action in a.NEW_MOVES:arsenal_pose(action,at)
		elif action=="" and a.walking:show_art(extra,9+int(a.stride/PI)%2,Vector2.ZERO,true)
		else:
			var index=foot_pose(action,at)
			show_art(foot,index,Vector2.ZERO,index in [3,5,7,10])
			if index==3:foot.position.y-=3
	if selected:
		var spear_art=a.phase==2 and a.weapon=="spear" and selected_frame not in [6,7]
		selected.weapon_extension=.23 if a.empowered and spear_art else 0.0
		selected.tint=FEEDBACK.tint(a.hurt,.12)
		selected.position+=FEEDBACK.recoil(a.hurt,.12,-a.facing)*.6
		if current=="lunge" and at<a.prep_for("lunge"):
			var coil=smoothstep(0,a.prep_for("lunge"),at)
			selected.lean=.012+coil*.025;selected.sink=coil*1.5
		elif current=="idle":selected.sink=sin(a.time*2.4)*.18
		elif current not in a.SPEAR.MOVES and a.windup>0 and selected_frame not in [1,2,9,10]:selected.lean=-.012
	was_action=a.action;queue_redraw()
func meteor_pose(action,at):
	var pose=actor.spear.pose(action,at)
	show_art(pressure if pose.bank=="pressure" else foot,pose.frame,Vector2.ZERO,pose.contact)
	var anticipation=1-smoothstep(-.40,-.06,pose.delta)
	selected.lean=.028*anticipation if not pose.contact else -.018
	selected.sink=1.4*(1-anticipation) if not pose.contact else .6
func arsenal_pose(action,at):
	var prep=actor.prep_for(action)
	match action:
		"lunge":show_art(arsenal,4 if at<prep else 5,Vector2.ZERO,at>=prep)
		"kick_thrust":
			if at<prep:show_art(arsenal,6)
			elif at<prep+.25:show_art(arsenal,7,Vector2.ZERO,true)
			else:show_art(foot,4 if at<prep+actor.KICK_FOLLOWUP else 5,Vector2.ZERO,at>=prep+actor.KICK_FOLLOWUP)
		"bow_double":
			var release=actor.bow_releasing(at)
			if release:show_art(foot,7,Vector2.ZERO,true)
			else:show_art(arsenal,8)
func pressure_pose(action,at):
	var prep=actor.prep_for(action)
	match action:
		"spin_rush":
			var index=0 if at<prep else (2+int((at-prep)*18)%3 if at<prep+.64 else 8)
			show_art(pressure,index,Vector2.ZERO,at>=prep)
		"triple_dash":
			var attacking=false
			for release in actor.pursuit_times():
				if at>=release and at<release+.32:attacking=true
			show_art(arsenal,5 if attacking else 4,Vector2.ZERO,attacking)
		"spear_return":
			var index=5 if at<prep else (6 if at<prep+.25 else (7 if actor.spear_in_flight() else 8))
			show_art(pressure,index,Vector2.ZERO,at>=prep)
		"spear_slam":show_art(pressure,11 if at<prep else 4,Vector2.ZERO,at>=prep)
		"bow_volley":
			if not actor.bow_releasing(at):show_art(pressure,9 if actor.aim.y<-.12 else 10)
			else:show_art(foot,7,Vector2.ZERO,true)
func dismount_pose():
	var a=actor;var t=a.dismount_t
	if t<.30:
		show_art(mounted,0,Vector2(0,-smoothstep(0,.3,t)*3));return
	horse.visible=true;horse.frame=0;horse.facing=-a.facing;horse.prepare(0)
	horse.position=Vector2(a.horse_x-a.position.x,horse.ground_offset())
	if t<a.DISMOUNT_LAND:
		var u=clampf((t-.30)/(a.DISMOUNT_LAND-.30),0,1)
		var offset=Vector2(-a.facing*46*smoothstep(0,1,u),lerpf(-47,0,u)-sin(u*PI)*28)
		show_art(extra,6,offset,true)
	elif t<1.28:
		departing_horse();show_art(extra,7,Vector2.ZERO,true)
	else:
		departing_horse();show_art(foot,0,Vector2(0,(1-smoothstep(1.28,1.52,t))*3))
func departing_horse():
	var a=actor
	if a.horse_away<0 or a.horse_away>=1.8:return
	var t=a.horse_away
	horse.visible=true
	horse.frame=0 if t<.12 else 1+int(fposmod(t,.64)/.16)%4
	horse.facing=-a.facing;horse.prepare(horse.frame);horse.bridge_left=0
	horse.position=Vector2(a.horse_x-a.position.x+a.facing*(t*t*260+t*120),horse.ground_offset())
func source_socket(art,index,pixel):
	var info=art.frame_info[index]
	var rect=info.source_rect
	var local=Vector2(pixel.x-float(rect[0])+8-float(info.anchor),pixel.y-float(rect[1])+8-art.bounds[index].end.y)*art.scale_unit
	return art.position+art.deform(local)*Vector2(-actor.facing,1)
func foot_socket(index,name):return source_socket(foot,index,FOOT_SOCKETS[index][name])
func projectile_origin():
	sync_pose(0)
	var index=7 # All predictive aim uses the actual relaxed-string release socket.
	return actor.position+foot_socket(index,"bow")
func _process(_dt):
	if not is_instance_valid(actor) or not actor.game.active() or actor.game.hitstop>0:return
	sync_pose(0)
