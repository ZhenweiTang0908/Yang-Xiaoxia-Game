extends "res://scripts/animation/actor_pose_art.gd"
# Reuses the original boss texture-grid renderer, with measured support anchors.
var frame_info=[]
var pose_duration=.07
func setup(folder,pixels_per_source,height=106.0):
	body_height=height;load_frames(folder,12);scale_unit=pixels_per_source
	frame_info=JSON.parse_string(FileAccess.get_file_as_string(folder+"/frames.json"))
	anchors=anchors.duplicate()
	for i in 12:anchors[i]=float(frame_info[i].anchor)
	var profile="knight/"+folder.get_file()
	if folder.get_file()=="arsenal" and height>130:profile="knight/mounted_arsenal"
	rigid_frames=true;use_anatomy_profile(profile,height)
	set_process(false)
func _process(_dt):pass
func transition_duration(_index):return pose_duration
func advance(dt):
	clock+=dt;bridge_left=maxf(0,bridge_left-dt);queue_redraw()
func ground_offset():return (bounds[frame].end.y-float(frame_info[frame].baseline))*frame_unit(frame)
func snap_pose():
	prepare(frame);bridge_left=0;queue_redraw()
# The new lunging key poses hold a high lance. Lower the forward arm/shaft
# progressively toward the authored waist-height collision, keeping feet planted.
var lower_weapon=false
var weapon_extension=0.0
func deform(p):
	var result=super.deform(p)
	if lower_weapon and frame in [4,5,10]:
		# Rotate the braced upper silhouette about the waist. Translating only
		# the forward shaft bends a rigid spear and detaches it from the hands.
		var pivot=Vector2(0,-body_height*.40)
		var weight=smoothstep(body_height*.30,body_height*.43,-p.y)
		var pitch=-.32 if frame==5 else -.26
		result+=((result-pivot).rotated(pitch)+pivot-result)*weight
	# Extend only the exposed shaft; the shoulder and torso retain their size.
	if weapon_extension>0 and p.y<-42:result.x-=maxf(0,-p.x-body_height*.75)*weapon_extension
	return result
