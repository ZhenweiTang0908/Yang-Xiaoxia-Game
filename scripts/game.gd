extends Node2D
const GOLD=Color("e6c38d")
const TEAL=Color("95d6c4")
const WHITE=Color("eeeade")
const SAVE=preload("res://scripts/core/save_store.gd")
const UPGRADE_IDS=["blade","spirit","brother"]
const TONIC_MAX=2
const TONIC_HEAL=35
const RELIC_IDS=["moon_1_roof","moon_1_seal","moon_2_roof","moon_2_seal","moon_3_roof","moon_3_seal"]
const RELIC_TEXT={
	"moon_1_roof":"初照 · 山门旧瓦仍记得并肩出发的人。",
	"moon_1_seal":"石印 · 微光沿机关纹路，指向未走完的路。",
	"moon_2_roof":"雾笺 · 风把渡口旧信藏在最高的檐角。",
	"moon_2_seal":"渡影 · 水面无桥，月色却替旅人留下倒影。",
	"moon_3_roof":"幽钟 · 钟声沉入石壁，只余一线温柔回响。",
	"moon_3_seal":"同行 · 最后的月痕写着：归途从来不是独行。"
}
var font:Font
var state="title"
var level
var world:Node2D
var player
var enemies=[]
var boss
var combat
var summon
var audio
var fx
var hud
var camera:Camera2D
var terrain
var progress={}
var pickups=[]
var section_clears={}
var journey_clears={}
var checkpoint_index=0
var kills=0
var elapsed=0.0
var attempt_started_elapsed=0.0
var attempt_started_kills=0
var attempt_started_upgrades=0
var stage_result={}
var death_source=""
var clock=0.0
var ambience_clock=0.0
var hitstop=0.0
var shake=0.0
var hint=""
var hint_time=0.0
var story_page=0
var story_time=0.0
var last_section=-1
var last_safe=Vector2(100,450)
var switching=false
var touch_ids={}
var is_touch=false
var qa_mode=false
var developer_mode=false
var telemetry=false
var tuning
var debug_panel
var subtitle=""
var subtitle_time=0.0
var pad_mode=false
var keyboard_nav=false
var keyboard_nav_repeat_left=0.0
var gamepad
var use_skeletal=false
var animation_lab
var scene_motion
var boss_rush=false
var challenge_elapsed=0.0
var challenge_tonic=TONIC_MAX
var challenge_entry_phase=1
var challenge_practice=false
var challenge_finish=-1.0
const CHALLENGE_LEVEL=4
# Fixed martial arts granted after bosses 1–3 of the boss rush.
const RUSH_UPGRADES=["blade","spirit","brother"]
const UPGRADE_NAMES={"blade":"破锋","spirit":"灵火","brother":"同心"}
var rush_reward=""
# Clock time a fight began; the HUD shows the stage name briefly from here.
var stage_banner=-10.0
func _ready():
	var arguments=OS.get_cmdline_user_args()
	qa_mode="--qa" in arguments or "--demon-qa" in arguments
	developer_mode=OS.has_feature("editor") or "--dev-tools" in arguments or qa_mode
	if not OS.has_feature("web") and not OS.has_feature("android"):
		var window=get_window()
		window.unresizable=false
		window.min_size=Vector2i(640,360)
		var screen=DisplayServer.screen_get_usable_rect()
		if screen.size.x>0 and screen.size.y>0:
			var scale_factor=minf(1.0,minf(screen.size.x*.92/1600.0,screen.size.y*.92/900.0))
			window.size=Vector2i(Vector2(1600,900)*scale_factor)
			window.position=screen.position+(screen.size-window.size)/2
	font=load("res://assets/art/ui_font.ttf")
	tuning=load("res://scripts/core/balance.gd").new()
	configure_input()
	gamepad=load("res://scripts/core/gamepad_input.gd").new();gamepad.setup(self)
	progress=SAVE.read_save();use_skeletal=progress.hero_mesh
	audio=load("res://scripts/core/audio_director.gd").new();audio.game=self;add_child(audio)
	world=Node2D.new();add_child(world)
	scene_motion=preload("res://scripts/animation/scene_motion.gd").new();scene_motion.game=self;add_child(scene_motion)
	camera=Camera2D.new();camera.position=Vector2(480,270);camera.position_smoothing_enabled=false;add_child(camera)
	hud=load("res://scripts/ui/hud.gd").new();hud.game=self;add_child(hud)
	debug_panel=load("res://scripts/ui/debug_panel.gd").new();debug_panel.game=self;add_child(debug_panel)
	is_touch=OS.has_feature("android") or DisplayServer.is_touchscreen_available()
	level=load("res://data/levels/level_1.tres")
	if "--qa" in arguments:call_deferred("run_qa")
	if "--demon-qa" in arguments:call_deferred("run_demon_qa")
	if "--telemetry" in arguments:telemetry=true
func configure_input():
	var bindings={"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"down":[KEY_S,KEY_DOWN],"jump":[KEY_SPACE,KEY_W,KEY_UP],"attack":[KEY_J],"bow":[KEY_K],"dash":[KEY_SHIFT,KEY_L],"sprint":[],"charge":[],"transform":[KEY_Q],"summon":[KEY_E],"item":[KEY_R]}
	for action in bindings:
		if not InputMap.has_action(action):InputMap.add_action(action)
		for key in bindings[action]:
			var e=InputEventKey.new();e.physical_keycode=key;InputMap.action_add_event(action,e)
func active():return state=="playing" and not switching
func _input(event):
	if event is InputEventMouseButton or event is InputEventScreenTouch:keyboard_nav=false
	if gamepad and gamepad.handle(event):get_viewport().set_input_as_handled();return
	if event is InputEventKey and event.pressed and state!="playing" and state!="debug":
		var directions={KEY_UP:Vector2.UP,KEY_W:Vector2.UP,KEY_DOWN:Vector2.DOWN,KEY_S:Vector2.DOWN,KEY_LEFT:Vector2.LEFT,KEY_A:Vector2.LEFT,KEY_RIGHT:Vector2.RIGHT,KEY_D:Vector2.RIGHT}
		var direction=directions.get(event.physical_keycode,Vector2.ZERO)
		if direction!=Vector2.ZERO:
			if not event.echo:
				keyboard_nav=true;pad_mode=false;hud.pad_move(direction);keyboard_nav_repeat_left=.36
			elif keyboard_nav and keyboard_nav_repeat_left<=0:
				hud.pad_move(direction);keyboard_nav_repeat_left=.16
			get_viewport().set_input_as_handled();return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_F2:
		debug_panel.toggle();get_viewport().set_input_as_handled();return
	if state=="debug":
		if event is InputEventKey and event.pressed and event.physical_keycode==KEY_ESCAPE:debug_panel.close()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if keyboard_nav and state!="playing" and event.physical_keycode in [KEY_ENTER,KEY_SPACE]:
			hud.pad_activate();get_viewport().set_input_as_handled();return
		match event.physical_keycode:
			KEY_ESCAPE:
				if state=="playing":state="paused";release_inputs()
				elif state=="paused":state="playing"
				elif state=="new_confirm":hud.action("new_confirm_back")
				elif state=="settings":state=hud.settings_return
				elif state=="stage_select":state=hud.stage_select_return
				elif state=="relic_journal":hud.action("relic_journal_back")
				elif state=="journey_records":hud.action("journey_records_back")
				elif state=="animation_lab":state=animation_lab.previous
				elif state=="controls":hud.action("controls_back")
			KEY_ENTER:
				if state=="title":hud.action("new")
				elif state=="new_confirm":hud.action("new_confirm_start")
				elif state=="story":advance_story()
				elif state=="dead":retry()
				elif state=="stage_clear":next_level()
			KEY_M:audio.toggle_mute()
	if active() and player:
		for action in ["jump","attack","bow","dash","sprint","transform","summon","item"]:
			if event.is_action_pressed(action) and not event.is_echo():
				if action=="item":use_tonic()
				else:player.enqueue(action)
		if event.is_action_released("jump"):player.enqueue("jump_release")
	if event is InputEventMouseButton and event.device!=InputEvent.DEVICE_ID_EMULATION and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		hud.handle_click(event.position)
	if event is InputEventScreenTouch:
		if event.device==InputEvent.DEVICE_ID_EMULATION:return
		is_touch=true
		if event.pressed:
			if hud.handle_click(event.position):return
			if active():
				for b in hud.touch_layout():
					if b.rect.has_point(event.position):
						touch_ids[event.index]=b.action;Input.action_press(b.action)
						if b.action=="item":use_tonic()
						elif b.action in ["jump","attack","bow","dash","sprint","transform","summon"]:player.enqueue(b.action)
		else:
			if touch_ids.has(event.index):
				var action=touch_ids[event.index];touch_ids.erase(event.index)
				if not touch_ids.values().has(action):
					Input.action_release(action)
					if action=="jump" and player:player.enqueue("jump_release")
func release_inputs():
	if gamepad:gamepad.cancel_hold()
	for action in ["left","right","down","jump","attack","bow","dash","sprint","charge","transform","summon","item"]:Input.action_release(action)
	touch_ids.clear()
	if player:player.edges.clear();player.clear_commands()
func _notification(what):
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and state=="playing" and not qa_mode:
		state="paused";release_inputs()
func _process(dt):
	if gamepad:gamepad.tick(dt)
	if state=="playing":keyboard_nav=false
	elif keyboard_nav:keyboard_nav_repeat_left=maxf(0.0,keyboard_nav_repeat_left-dt)
	world.visible=state not in ["title","new_confirm","story","settings","animation_lab","controls","relic_journal","journey_records"]
	clock+=dt
	if state=="story":story_time+=dt
	if active():
		if hitstop<=0:ambience_clock+=dt
		subtitle_time=maxf(0,subtitle_time-dt)
		if is_challenge():challenge_elapsed+=dt
		else:elapsed+=dt
		if subtitle_time<=0:hint_time=maxf(0,hint_time-dt)
		shake=maxf(0,shake-dt*28)
		var desired=Vector2(clampf(scene_motion.display_position(player).x+170,480,level.length-480),270)
		if (boss.active_battle and not boss.dead) or is_challenge():desired.x=boss.arena.get_center().x
		camera.position=camera.position.lerp(desired,1-exp(-dt*6))
		camera.offset=Vector2(sin(clock*73)*minf(shake,3.5),cos(clock*91)*minf(shake,3.5)*.6) if shake>0 and progress.screen_shake else Vector2.ZERO
	else:camera.offset=Vector2.ZERO
func _physics_process(dt):
	if not active():return
	hitstop=maxf(0,hitstop-dt)
	if hitstop>0:return
	if not player.is_carried() and player.is_on_floor():last_safe=player.position
	var section=clampi(int(player.position.x/4000),0,level.section_names.size()-1)
	if section!=last_section:
		last_section=section
	for i in level.checkpoints.size():
		if i>checkpoint_index and player.position.x>=level.checkpoints[i]:
			checkpoint_index=i;progress.checkpoint=i;progress.entry_section=0;progress.tonic=TONIC_MAX;player.health=100;summon.reset(gourd_available());audio.play("checkpoint",0)
			fx.recovery(player.position);show_hint("山灯共鸣 · 选择一式武学",4);begin_upgrade(i)
			break
	for p in pickups:
		if p.taken or (p.kind=="spirit" and player.sheep()):continue
		if Vector2(p.x,p.y).distance_to(player.position-Vector2(0,20))<28:
			p.taken=true;audio.play("pickup",0);fx.burst(Vector2(p.x,p.y),10,GOLD if p.kind in ["bow","relic"] else TEAL,65)
			match p.kind:
				"bow":player.has_bow=true;progress.bow=true;show_hint("拾得山行弓 · K 射箭，J 仍然使用近战",5);save_progress()
				"spirit":player.gain_spirit(28);show_hint("灵息入体 · 觉醒增加",2)
				"heal":player.health=minf(100,player.health+30);show_hint("饮下灵泉 · 生命恢复",2)
				"relic":collect_relic(p.id)
	if level.single_boss:
		if boss.dead:
			challenge_finish=maxf(0,challenge_finish-dt) if challenge_finish>=0 else 2.4
			if challenge_finish==0:finish_level()
	elif player.position.x>level.length-260 and boss.dead:finish_level()
func has_journey_progress():
	return int(progress.get("level",1))>1 or int(progress.get("checkpoint",0))>0 or int(progress.get("entry_section",0))>0 \
		or bool(progress.get("bow",false)) or bool(progress.get("gourd",false)) or bool(progress.get("story_seen",false)) \
		or bool(progress.get("completed",false)) or not progress.get("upgrades",[]).is_empty() or not progress.get("pending_upgrade",{}).is_empty() \
		or int(progress.get("rush_stage",1))>1 or not progress.get("rush_clears",[]).is_empty() \
		or int(progress.get("tonic",TONIC_MAX))<TONIC_MAX or elapsed>.5 or kills>0 or not journey_clears.is_empty()
# The boss rush is the default journey. rush=false still opens the preserved
# three-level journey with its minions, checkpoints and upgrade choices.
func start_new(rush=true):
	var options={}
	for key in ["music","sfx","ambience","muted","screen_shake","hero_mesh","boss_voice","journey_mode","relics","records"]:options[key]=progress[key]
	progress=SAVE.defaults()
	for key in options:progress[key]=options[key]
	boss_rush=rush
	if rush:progress.bow=true;progress.gourd=true
	elapsed=0;kills=0;journey_clears={};stage_result={};load_stage(1,0);save_progress()
func continue_game(rush=true):
	boss_rush=rush;challenge_practice=false;challenge_entry_phase=1
	if rush:load_stage(progress.get("rush_stage",1),0)
	else:load_stage(progress.level,progress.checkpoint,progress.entry_section)
func is_challenge():return level!=null and level.single_boss and not boss_rush
# The knight challenge is a separate entrance: it never overwrites the journey's
# level, checkpoint, equipment, tonic or timer.
func start_challenge(number=CHALLENGE_LEVEL,entry_phase=1):
	if switching:return
	boss_rush=false
	challenge_entry_phase=2 if entry_phase==2 else 1
	challenge_practice=challenge_entry_phase==2
	load_stage(number,0)
func jump_to_stage(number,section=0):
	if switching or number<1 or number>4:return
	boss_rush=true;challenge_practice=false;challenge_entry_phase=1
	progress.pending_upgrade={};progress.tonic=TONIC_MAX;progress.rush_knight_foot=false
	load_stage(number,0);save_progress()
func load_stage(number,checkpoint,entry_section=0):
	if switching:return
	switching=true;release_inputs()
	if is_instance_valid(summon):summon.reset(false)
	subtitle_time=0;hint_time=0
	scene_motion.clear()
	for child in world.get_children():child.free()
	enemies.clear();player=null;boss=null
	level=load(("res://data/arenas/boss_" if boss_rush else "res://data/levels/level_")+str(number)+".tres")
	entry_section=0 if level.single_boss else (2 if entry_section==6 else entry_section)
	checkpoint=clampi(checkpoint,0,level.checkpoints.size()-1)
	checkpoint_index=checkpoint;last_section=-1;hitstop=0;shake=0;death_source="";challenge_finish=-1.0
	if level.single_boss:challenge_tonic=TONIC_MAX
	if boss_rush:progress.rush_stage=number
	if not level.single_boss:progress.level=number;progress.checkpoint=checkpoint;progress.entry_section=entry_section
	terrain=load("res://scripts/world/terrain.gd").new();world.add_child(terrain);terrain.build(self)
	combat=load("res://scripts/combat/combat.gd").new();combat.game=self;world.add_child(combat)
	fx=load("res://scripts/combat/effects.gd").new();fx.game=self;world.add_child(fx)
	player=load("res://scripts/actors/player.gd").new();player.game=self;world.add_child(player)
	last_safe=Vector2(8100 if entry_section==2 else level.checkpoints[checkpoint],450);player.reset(last_safe,progress.bow or level.single_boss);scene_motion.register(player)
	for spawn in level.spawns:
		if spawn.x<last_safe.x-160:continue
		var e=load("res://scripts/actors/enemy.gd").new();e.setup(self,spawn);world.add_child(e);enemies.append(e);scene_motion.register(e)
	boss=load(level.boss_script if level.boss_script!="" else "res://scripts/actors/boss.gd").new();boss.setup(self,level.boss_id,level.boss_x);world.add_child(boss);enemies.append(boss);scene_motion.register(boss)
	if is_challenge() and challenge_entry_phase==2:boss.enter_foot_challenge()
	# Once the rush knight has dismounted, retries and continues resume the foot duel.
	elif boss_rush and level.boss_id=="knight" and rush_knight_foot():boss.enter_foot_challenge()
	summon=load("res://scripts/actors/summon.gd").new();summon.game=self;world.add_child(summon);summon.reset(gourd_available())
	pickups=[]
	section_clears={}
	for item in level.pickups:
		var data=item.duplicate();data.taken=(data.kind=="bow" and progress.bow) or (data.kind=="relic" and data.id in progress.get("relics",[]));pickups.append(data)
	camera.position=Vector2(clampf(player.position.x+170,480,level.length-480),270)
	state="playing";switching=false;audio.start();audio.change_music(number,false)
	attempt_started_elapsed=elapsed;attempt_started_kills=kills;attempt_started_upgrades=progress.get("upgrades",[]).size()
	challenge_elapsed=0.0;stage_banner=ambience_clock
	if not level.single_boss:resume_pending_upgrade()
func gourd_available():return progress.gourd or (level!=null and level.single_boss)
func upgrade_level(id):
	return progress.get("upgrades",[]).count(id)
func upgrade_multiplier(id,per_level):
	return 1.0+upgrade_level(id)*per_level
func begin_upgrade(checkpoint):
	progress.pending_upgrade={"level":level.number,"checkpoint":checkpoint}
	state="upgrade";release_inputs();save_progress()
func resume_pending_upgrade():
	var pending=progress.get("pending_upgrade",{})
	if pending is Dictionary and not pending.is_empty() and int(pending.get("level",0))==level.number:
		state="upgrade";release_inputs()
func choose_upgrade(id):
	if state!="upgrade" or id not in UPGRADE_IDS:return false
	var pending=progress.get("pending_upgrade",{})
	if not (pending is Dictionary) or pending.is_empty():return false
	var upgrades=progress.get("upgrades",[]).duplicate()
	upgrades.append(id);progress.upgrades=upgrades;progress.pending_upgrade={}
	state="playing";audio.play("checkpoint",0);fx.recovery(player.position);save_progress()
	show_hint("习得「"+UPGRADE_NAMES[id]+"」· 当前第 "+str(upgrade_level(id))+" 层",4)
	return true
func set_hero_animation(modern):
	use_skeletal=modern;progress.hero_mesh=modern
	if is_instance_valid(player):
		var visual=player.skeletal_visual
		visual.blade_trail.clear();visual.cloth_anchor=Vector2.INF
		var motion=visual.painted_motion
		motion.last_state="";motion.rig.transition_pose.clear();motion.rig.blade_history.clear()
		motion.rig.planted=[null,null];motion.rig.secondary.reset()
		player.update_animation();visual._process(0)
		if modern and not player.form_visual and not player.is_carried():
			var rig=motion.rig
			rig.rotation=0;rig.scale=Vector2(player.facing,1)*rig.game_scale
			rig.position=Vector2(-96*player.facing,-199)*rig.game_scale
			rig.grounded_override=player.is_on_floor();motion.sample_actor_pose(visual.desired_state(),0);rig.queue_redraw()
	save_progress()
func save_progress():
	if not qa_mode:SAVE.write_save(progress)
func show_hint(message,duration=4.0):
	# Routine pickups, tutorials and ability names already have visual/HUD feedback.
	var concise=""
	if message.begins_with("拾得山行弓"):concise="获得弓箭 · K 射击"
	elif message.begins_with("月痕 "):concise="获得月痕"
	elif message.begins_with("山门已开"):concise="出口已开启 →"
	elif message.begins_with("石印已开启"):concise="闸门已开启"
	elif message.begins_with("月露已用尽"):concise="月露已用尽"
	elif message.begins_with("生命已满"):concise="生命已满"
	elif message.begins_with("通关月下山门"):concise="葫芦尚未获得"
	elif message.begins_with("在上方石台"):concise="尚未获得弓箭"
	if concise.is_empty():return
	if hint_time>0 and hint==concise:return
	hint=concise;hint_time=minf(duration,1.8)
	if concise in ["月露已用尽","生命已满","葫芦尚未获得","尚未获得弓箭"]:
		audio.play("ui_error",-3)
		hud.resource_feedback=1.0
func use_tonic():
	if not active() or not is_instance_valid(player):return false
	var charges=tonic_count()
	if charges<=0:show_hint("月露已用尽 · 山灯会重新补给",2.5);return false
	if player.health>=100:show_hint("生命已满 · 月露未消耗",2.5);return false
	var healed=minf(TONIC_HEAL,100-player.health)
	player.health+=healed
	if is_challenge():challenge_tonic=charges-1
	else:progress.tonic=charges-1
	audio.play("pickup",-2);fx.recovery(player.position);show_hint("饮下月露 · 生命 +"+str(int(healed))+" · 剩余 "+str(tonic_count()),3);save_progress()
	return true
func tonic_count():return clampi(challenge_tonic if is_challenge() else int(progress.get("tonic",0)),0,TONIC_MAX)
func relaxed_journey():return progress.get("journey_mode","standard")=="relaxed"
func incoming_damage(amount):return amount*.7 if relaxed_journey() else amount
func death_guide(source=death_source):
	match source:
		"fall":return {"title":"失足坠落","tip":"临近边缘先收住连斩；空中可向安全平台修正方向。"}
		"spikes":return {"title":"庭院地刺","tip":"地面机关抬升时先停步，尖刺完全伸出前仍有跃过时机。"}
		"ritual":return {"title":"幽钟祭阵","tip":"阵纹亮起就是预警；立即移向未发光的安全区域。"}
		"binding_rune":return {"title":"缚灵符阵","tip":"符纹会锁定施放时的位置，看见地面印记后继续移动。"}
		"pounce_impact","slam","stone_impact":return {"title":"扑击落点","tip":"落点会先显形；离开中心，等冲击结束后再近身反击。"}
		"sweep","blade_sweep","antler_sweep","spectral_horn":return {"title":"近身横扫","tip":"蓄势时拉开距离，或用闪避的短暂无敌穿过攻击。"}
		"dart","blade":return {"title":"飞刃命中","tip":"保持横向移动；多枚飞刃展开后，从间隙穿过比后退更稳。"}
		"orb","ghost_orb":return {"title":"追魂灵弹","tip":"先把灵弹引向一侧，再反向移动；不要过早交出闪避。"}
		"rift","shadow","ground_rift","stone_wave":return {"title":"地脉裂隙","tip":"裂纹出现后不要停在原位，连续波纹之间保留一步空间。"}
		"spirit_lightning":return {"title":"引魂雷击","tip":"雷柱锁定前会照亮落点，持续移动即可离开狭长范围。"}
		"rain":return {"title":"幽光落雨","tip":"观察地面留下的宽阔空档，进入空档后不要追着雨幕移动。"}
		"spirit_beam","breath":return {"title":"幽焰长息","tip":"长息开始后方向固定，绕到施术者身后再输出。"}
		"knight_lance":return {"title":"骑枪掠袭","tip":"枪杆压到腋下就是冲锋前兆；冲锋不会转向，跳过枪尖或横向让开。"}
		"knight_hoof":return {"title":"战马蹄击","tip":"马抬前蹄只打前方，回头收腿只踢后方；退开后再反击。"}
		"knight_butt":return {"title":"枪柄压击","tip":"高抬手肘后会向下压，贴身时先退半步。"}
		"knight_thrust":return {"title":"长矛点刺","tip":"收肘压肩后直刺，出手前一瞬才固定方向，翻滚穿过或退出距离。"}
		"knight_counter":return {"title":"绞枪反刺","tip":"横枪架势时别用普通攻击硬打正面；用升龙斩或蓄爆破架。"}
		"knight_wave":return {"title":"三叠枪气","tip":"枪气横贯全场，翻滚挡不住；看清每次抬臂，及时轻跳越过。"}
		"knight_arrow":return {"title":"连珠追猎","tip":"连射会分别锁定方向；交替跳跃、翻滚与变向，注意头顶虚像的延迟补射。"}
		"knight_spin_rush":return {"title":"旋枪破阵","tip":"收枪旋身后沿锁定方向疾冲；跳过枪圈上缘或翻滚穿过，别一直沿同一方向逃。"}
		"knight_triple_dash":return {"title":"三折追刺","tip":"每次收枪会重新对向；战怒时有五段，看准每次抬手再换边。"}
		"knight_spear":return {"title":"回锋掷矛","tip":"飞矛先去后回；跳开低位轨迹，注意回程并非第一次闪过就安全。"}
		"soul_arrow","soul_eagle":return {"title":"魂骑补射","tip":"空中虚像拉弓后才射击；移开瞄准位置，魂箭命中会短暂减速，但仍可跳跃与翻滚。"}
		"soul_soldier":return {"title":"枪后虚兵","tip":"金紫蓄势表示战怒强化，枪击后还会跟出两道虚兵；别立即回身抢攻。"}
		"knight_spear_slam":return {"title":"踏进重挑","tip":"骑士高举长枪后突进挑击，覆盖头顶；翻滚穿过或退出枪锋范围。"}
		"knight_dust":return {"title":"下马尘气","tip":"骑士落地的尘气必定命中，转阶段前保持足够生命。"}
		_:return {"title":"力尽倒下","tip":"观察敌人头顶与地面的预兆，保留一次闪避应对最后一击。"}
func relic_count():
	var found={}
	for id in progress.get("relics",[]):
		if id in RELIC_IDS:found[id]=true
	return found.size()
func stage_relic_count(number):
	var count=0;var prefix="moon_"+str(number)+"_"
	for id in progress.get("relics",[]):
		if id in RELIC_IDS and id.begins_with(prefix):count+=1
	return count
func stage_record(number,mode):
	return progress.get("records",{}).get(str(number),{}).get(mode,{})
func update_stage_record(result):
	var number=int(result.get("level",0));var mode=progress.get("journey_mode","standard")
	if number<1 or number>CHALLENGE_LEVEL or mode not in ["standard","relaxed"]:return false
	var records=progress.get("records",{}).duplicate(true);var stage_records=records.get(str(number),{}).duplicate(true)
	var previous=stage_records.get(mode,{})
	var seconds=maxf(0,float(result.get("seconds",0)));var kills=maxi(0,int(result.get("kills",0)));var clears=clampi(int(result.get("clears",0)),0,4)
	stage_records[mode]={
		"completions":int(previous.get("completions",0))+1,
		"best_seconds":seconds if previous.is_empty() or float(previous.get("best_seconds",0))<=0 else minf(seconds,float(previous.best_seconds)),
		"best_kills":maxi(kills,int(previous.get("best_kills",0))),
		"best_clears":maxi(clears,int(previous.get("best_clears",0)))
	}
	records[str(number)]=stage_records;progress.records=records
	return true
func collect_relic(id):
	if id not in RELIC_IDS or id in progress.get("relics",[]):return false
	var relics=progress.get("relics",[]).duplicate();relics.append(id);progress.relics=relics
	player.gain_spirit(15);fx.ring(player.position-Vector2(0,24),GOLD,46,.65)
	show_hint("月痕 "+str(relic_count())+" / 6 · "+RELIC_TEXT[id],5);save_progress()
	return true
func section_progress(section):
	var total=0;var defeated=0
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.kind=="boss" or enemy.section!=section:continue
		total+=1
		if enemy.dead:defeated+=1
	var key=str(level.number)+":"+str(section)
	return {"total":total,"defeated":defeated,"cleared":section_clears.has(key)}
func on_enemy_defeated(enemy):
	if not active() or not is_instance_valid(enemy) or enemy.kind=="boss":return false
	var progress_state=section_progress(enemy.section)
	var key=str(level.number)+":"+str(enemy.section)
	if progress_state.total==0 or progress_state.defeated<progress_state.total or section_clears.has(key):return false
	section_clears[key]=true
	journey_clears[key]=true
	var healed=minf(12,100-player.health)
	player.health+=healed;var spirit_gain=player.gain_spirit(20)
	audio.play("pickup",-2);fx.recovery(player.position)
	var reward_text="生命已恢复" if healed<=0 else "生命 +"+str(int(healed))
	if spirit_gain>0:reward_text+=" · 觉醒 +"+str(int(spirit_gain))
	show_hint("本段肃清 · "+reward_text,4)
	return true
func safe_ground(p):
	for dx in [0,-45,45,-90,90]:
		var x=clampf(p.x+dx,15,level.length-15)
		var query=PhysicsRayQueryParameters2D.create(Vector2(x,p.y-8),Vector2(x,650),5)
		var result=get_world_2d().direct_space_state.intersect_ray(query)
		if result:return result.position
	return last_safe
func fall_recover():
	player.take_damage(18,0,"fall")
	if active():player.position=last_safe;player.velocity=Vector2.ZERO;player.invincible=1.2;scene_motion.reset(player)
func die(source="unknown"):
	death_source=source;state="dead";audio.play("death",0);combat.clear();summon.reset(gourd_available());release_inputs();save_progress()
func rush_knight_foot():return bool(progress.get("rush_knight_foot",false))
# Death-screen choice to replay the whole knight fight from horseback.
func retry_mounted():
	progress.rush_knight_foot=false;save_progress();retry()
func retry():
	if boss_rush:
		progress.tonic=TONIC_MAX
		call_deferred("load_stage",level.number,0);return
	if is_challenge():
		call_deferred("start_challenge",CHALLENGE_LEVEL,challenge_entry_phase)
	else:call_deferred("load_stage",level.number,checkpoint_index,progress.get("entry_section",0))
func boss_defeated():
	audio.play("win",0);audio.change_music(level.number,false)
	if boss_rush:
		summon.clear_seal();progress.tonic=TONIC_MAX;fx.recovery(player.position);return
	if is_challenge():summon.clear_seal();show_hint(boss.spec.title+"已败 · 骑场归于寂静",4)
	else:show_hint("山门已开 · 前往右侧出口",6)
func finish_level():
	if boss_rush and state!="playing":return
	release_inputs();combat.clear();summon.reset(gourd_available())
	capture_stage_result()
	if not stage_result.get("practice",false):update_stage_record(stage_result)
	if boss_rush:
		progress.rush_knight_foot=false
		var clears=progress.get("rush_clears",[]).duplicate()
		rush_reward=""
		if level.number not in clears:
			clears.append(level.number);progress.rush_clears=clears
			# The between-boss martial art is granted automatically instead of a choice.
			if level.number<4:
				rush_reward=RUSH_UPGRADES[level.number-1]
				var upgrades=progress.get("upgrades",[]).duplicate();upgrades.append(rush_reward);progress.upgrades=upgrades
		progress.tonic=TONIC_MAX;progress.pending_upgrade={}
		if level.number<4:
			progress.rush_stage=level.number+1;state="stage_clear";save_progress()
		else:
			state="win";progress.rush_completed=true;save_progress();audio.play("ending",0)
		return
	save_progress()
	if is_challenge():state="stage_clear";return
	if level.number==1 and not progress.story_seen:
		state="story";story_page=0;story_time=0;audio.play("story",0)
	elif level.number==3:
		state="win";progress.completed=true;save_progress();audio.play("ending",0)
	else:state="stage_clear";save_progress()
func capture_stage_result():
	var clear_count=0;var prefix=str(level.number)+":"
	for key in journey_clears:
		if str(key).begins_with(prefix):clear_count+=1
	stage_result={
		"practice":is_challenge() and challenge_practice,
		"level":level.number,
		"seconds":challenge_elapsed if is_challenge() else maxf(0,elapsed-attempt_started_elapsed),
		"kills":(1 if boss.dead else 0) if is_challenge() else maxi(0,kills-attempt_started_kills),
		"clears":clear_count,
		"upgrades":maxi(0,progress.get("upgrades",[]).size()-attempt_started_upgrades)
	}
func advance_story():
	story_page+=1;story_time=0;audio.play("ui",-3)
	if story_page>=3:complete_story()
func complete_story():
	progress.gourd=true;progress.story_seen=true;summon.unlock();state="stage_clear";save_progress()
func next_level():
	if boss_rush:
		if level.number<4:call_deferred("load_stage",level.number+1,0)
		return
	if is_challenge():retry();return
	if level.number<3:
		progress.level=level.number+1;progress.checkpoint=0;progress.tonic=TONIC_MAX;save_progress()
		call_deferred("load_stage",level.number+1,0)
func return_title():
	if is_instance_valid(summon):summon.reset(gourd_available())
	release_inputs();state="title";save_progress()
func run_qa():
	qa_mode=true;start_new()
	await get_tree().create_timer(.5).timeout
	await RenderingServer.frame_post_draw
	capture_qa("v2_gameplay.png")
	progress.gourd=true;summon.reset(true);player.position=Vector2(1420,450);player.spirit=100;player.enqueue("transform");summon.request()
	await get_tree().create_timer(1.7).timeout
	await RenderingServer.frame_post_draw
	capture_qa("v2_brothers.png")
	load_stage(2,2);player.position=safe_ground(Vector2(level.boss_x-220,450))
	scene_motion.reset(player)
	await get_tree().create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	capture_qa("v2_boss.png")
	state="title"
	await RenderingServer.frame_post_draw
	capture_qa("v2_title.png")
	audio.stop_all()
	await get_tree().create_timer(.15).timeout
	get_tree().quit()

func capture_qa(filename):
	var folder="/private/tmp/yang-v2-client-qa/"
	DirAccess.make_dir_recursive_absolute(folder)
	get_viewport().get_texture().get_image().save_png(folder+filename)

func say_line(line,voice_key):
	if not audio.voice(voice_key):return false
	subtitle=line;subtitle_time=clampf(audio.voice_player.stream.get_length()+.4,2.0,8.0)
	return true
func ally_target(at):
	if is_instance_valid(summon) and summon.phase=="active" and is_instance_valid(summon.brother):
		var ally=summon.brother
		if not ally.dead and (player.is_carried() or at.distance_to(ally.position)<at.distance_to(player.position)*.85):return ally
	return player

func run_demon_qa():
	qa_mode=true;tuning.reset();start_new();player.position=Vector2(530,450);player.health=29
	for e in enemies:e.set_physics_process(false);e.visible=false;e.dead=true
	summon.reset(true);summon.request()
	await get_tree().create_timer(1.35).timeout
	summon.brother.arrive()
	await get_tree().create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	capture_qa("demon_carry.png")
	await get_tree().create_timer(6.8).timeout
	debug_panel.toggle()
	await RenderingServer.frame_post_draw
	capture_qa("demon_debug.png")
	audio.stop_all();await get_tree().create_timer(.2).timeout;get_tree().quit()

func _exit_tree():
	if gamepad:gamepad.cleanup()

func open_animation_lab():
	if not developer_mode:return
	var from=state
	if not is_instance_valid(animation_lab):
		animation_lab=load("res://scripts/animation/animation_lab.gd").new();animation_lab.game=self;add_child(animation_lab)
	animation_lab.previous=from;state="animation_lab";release_inputs();animation_lab.restart()
