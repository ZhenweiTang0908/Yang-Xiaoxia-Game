extends Node2D
const MOTION=preload("res://scripts/animation/hero_motion.gd")
var camera:Camera3D
var ribbon=[]
var render_attack=0.0
var actor
var viewport:SubViewport
var model
var state="idle"
var state_age=0.0
var clock=0.0
var phase=0.0
var pose={}
var transition_from={}
var preview=false
var playback_rate=1.0
var preview_state="idle"
var preview_time=0.0
var preview_speed=225.0
var preview_ground=true
var step_half=-1
var body_height=52.8
var facing=1.0
var alpha=1.0
func _ready():
 viewport=SubViewport.new();viewport.name="PixelRender";viewport.size=Vector2i(192,160);viewport.own_world_3d=true;viewport.transparent_bg=true
 viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;viewport.msaa_3d=Viewport.MSAA_DISABLED;add_child(viewport)
 var root3d=Node3D.new();viewport.add_child(root3d)
 var world=WorldEnvironment.new();var env=Environment.new();env.background_mode=Environment.BG_CLEAR_COLOR;env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("a3bac5");env.ambient_light_energy=.65;env.tonemap_mode=Environment.TONE_MAPPER_LINEAR;world.environment=env;root3d.add_child(world)
 var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-35,-30,0);light.light_color=Color("ffe2bd");light.light_energy=1.15;root3d.add_child(light)
 var fill=DirectionalLight3D.new();fill.rotation_degrees=Vector3(15,145,0);fill.light_color=Color("88bbc4");fill.light_energy=.45;root3d.add_child(fill)
 camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=2.6;camera.position=Vector3(0,.78,6);camera.current=true;root3d.add_child(camera)
 model=load("res://scripts/animation/blender_hero_model.gd").new();model.name="YangXiaoxiaRig";root3d.add_child(model)
 pose=MOTION.sample("idle",0);transition_from=pose.duplicate(true);model.apply_pose(pose)
func desired_state():
 if preview:return preview_state
 if actor.hurt_anim>0:return "hurt"
 if actor.dash_time>0:return "dash" if actor.sprinting else "roll"
 if actor.charge>0 or actor.blast_anim>0:return "charge"
 if actor.bow_anim>0:return "bow"
 if actor.attack_elapsed>=0:return "slash"+str(actor.combo)
 if actor.land_anim>0 and (actor.land_anim>.09 or absf(actor.velocity.x)<12):return "land"
 if not actor.is_on_floor():return "jump" if actor.velocity.y<0 else "fall"
 if absf(actor.velocity.x)>12:return "run"
 return "idle"
func _process(dt):
 if preview:dt*=playback_rate
 if not preview:
  visible=is_instance_valid(actor) and actor.game.use_skeletal and not actor.sheep() and not actor.form_visual and not actor.is_carried()
  if not visible:viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED;ribbon.clear();return
  viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
  if not actor.game.active() or actor.game.hitstop>0:return
  facing=actor.facing;alpha=.3 if actor.invincible>0 and int(actor.anim_clock*20)%2==0 else 1
 clock+=dt
 var desired=desired_state()
 if desired!=state:
  transition_from=pose.duplicate(true);state=desired;state_age=0;render_attack=0
 state_age+=dt
 var speed=preview_speed if preview else absf(actor.velocity.x)
 phase+=dt*sqrt(clampf(speed/225.0,0,1))*TAU/MOTION.RUN_PERIOD
 if state.begins_with("slash") and not preview:
  render_attack=minf(render_attack+dt,actor.attack_elapsed+1.0/Engine.physics_ticks_per_second)
 var t=preview_time if preview else (render_attack if state.begins_with("slash") else state_age)
 var target=MOTION.sample(state,t,phase,sqrt(clampf(speed/225.0,0,1)))
 var blend=smoothstep(0,.075 if state.begins_with("slash") else .10,state_age)
 pose={}
 for key in model.bones:
  pose[key]=transition_from.get(key,Vector3.ZERO).lerp(target.get(key,Vector3.ZERO),blend)
 pose.offset=transition_from.get("offset",Vector3.ZERO).lerp(target.offset,blend)
 model.preview_mode=preview
 model.animate(state,t,dt)
 update_ribbon(dt,t)
 model.blade.visible=state not in ["bow","roll"]
 model.bow.visible=state=="bow"
 if not preview and state=="run" and actor.is_on_floor():
  var half=int(phase/PI)
  if step_half!=half:
   step_half=half;actor.game.audio.play("step"+str(half%3),-12)
 else:step_half=int(phase/PI)
 queue_redraw()
func _draw():
 if not viewport:return
 draw_ribbon()
 var pivot=Vector2(0,-24) if state=="roll" else Vector2.ZERO
 var angle=TAU*clampf(state_age/.18,0,1)*facing if state=="roll" else 0.0
 draw_set_transform(pivot,angle,Vector2(facing,1))
 draw_texture_rect(viewport.get_texture(),Rect2(Vector2(-53.16,-70.88)-pivot,Vector2(106.32,88.6)),false,Color(1,1,1,alpha))

func project_point(point):
 var uv=camera.unproject_position(point)
 return Vector2(-53.16,-70.88)+uv*Vector2(106.32/192,88.6/160)
func update_ribbon(dt,t):
 for sample in ribbon:sample.age+=dt
 ribbon=ribbon.filter(func(sample):return sample.age<.105)
 if not state.begins_with("slash"):return
 var attack=MOTION.ATTACKS[int(state.right(1))-1]
 if t>=attack.hit-.055 and t<=attack.hit+.075:
  var tip=project_point(model.blade.global_transform*Vector3(.63,0,0));var base=project_point(model.blade.global_transform*Vector3(.36,0,0))
  ribbon.append({"tip":to_global(tip*Vector2(facing,1)),"base":to_global(base*Vector2(facing,1)),"age":0.0})
func draw_ribbon():
 for i in range(1,ribbon.size()):
  var a=ribbon[i-1];var b=ribbon[i]
  var fade=pow(maxf(0,1-a.age/.105),1.2)*.50
  var points=PackedVector2Array([to_local(a.base),to_local(a.tip),to_local(b.tip),to_local(b.base)])
  if points[1].distance_to(points[2])<.1:continue
  # Two triangles remain well-defined when the sword changes direction.
  draw_colored_polygon(PackedVector2Array([points[0],points[1],points[2]]),Color(.48,.85,.88,fade))
  draw_colored_polygon(PackedVector2Array([points[0],points[2],points[3]]),Color(.48,.85,.88,fade))
  draw_line(points[1],points[2],Color(.9,1,1,fade*1.8),.65)
