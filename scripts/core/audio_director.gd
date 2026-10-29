extends Node
const CATALOG=preload("res://scripts/core/audio_catalog.gd")
const ENEMY_AUDIO=preload("res://scripts/combat/enemy_audio.gd")
const BOSS_DIALOGUE=preload("res://scripts/core/boss_dialogue.gd")
var game
var bank={}
var melee_players=[]
var layer_players=[]
var last_variant={}
var recent_events={}
var melee_history=[]
var audition_events=[]
var audition_active=false
var audition_age=0.0
var duck_db=0.0
var impact_duck=0.0
var enemy_players=[]
var warning_players=[]
var hurt_players=[]
var enemy_recent={}
var enemy_history=[]
const SWING_LEAD=[.035,.04,.055]
var players=[]
var music_players=[]
var ambience:AudioStreamPlayer
var ambience_players=[]
var ambience_selected=0
var ambience_fade=1.0
var ambience_target=""
var music_target=""
var selected=0
var fade=1.0
var started=false
var muted=false
var voice_player:AudioStreamPlayer
var effort_player:AudioStreamPlayer
var effort_last=-10000
var effort_history=[]
var voice_identity=""
var voice_source="classic"
var voice_preview=false
func _ready():
	for key in CATALOG.SFX:bank[key]=load("res://assets/audio/"+key+".wav")
	for profile in ENEMY_AUDIO.profiles().values():
		for stage in ["warning","charge","release","impact","landing","recover"]:
			if not profile.has(stage):continue
			var key=profile[stage];bank[key]=load("res://assets/audio/"+key+".wav")
	bank["reset_moon_fall"]=load("res://assets/audio/reset_moon_fall.wav")
	for i in 8:
		var p=AudioStreamPlayer.new();p.bus="SFX";add_child(p);enemy_players.append(p)
	for i in 4:
		var p=AudioStreamPlayer.new();p.bus="SFX";add_child(p);hurt_players.append(p)
	for i in 4:
		var p=AudioStreamPlayer.new();p.bus="SFX";add_child(p);warning_players.append(p)
	for family in ["swing","soft","stone","boss","block"]:
		for combo in range(1,4):
			for variant in 3:
				var key="melee_"+family+str(combo)+"_"+str(variant);bank[key]=load("res://assets/audio/"+key+".wav")
	for i in 4:
		var p=AudioStreamPlayer.new();p.bus="SFX";add_child(p);melee_players.append(p)
	for i in 16:
		var p=AudioStreamPlayer.new();p.bus="SFX";add_child(p);players.append(p)
	for i in 6:
		var p=AudioStreamPlayer.new();p.bus="SFX";add_child(p);layer_players.append(p)
	for i in 2:
		var p=AudioStreamPlayer.new();p.bus="Music";add_child(p);music_players.append(p)
	for i in 2:
		var p=AudioStreamPlayer.new();p.bus="Ambience";add_child(p);ambience_players.append(p)
	ambience=ambience_players[0]
	for name in ["SFX","Music","Ambience"]:
		if AudioServer.get_bus_index(name)<0:AudioServer.add_bus();AudioServer.set_bus_name(AudioServer.bus_count-1,name)
	var limiter=AudioEffectLimiter.new();limiter.ceiling_db=-1.0
	var bus=AudioServer.get_bus_index("SFX")
	if AudioServer.get_bus_effect_count(bus)==0:AudioServer.add_bus_effect(bus,limiter)
	voice_player=AudioStreamPlayer.new();voice_player.bus="SFX";add_child(voice_player)
	effort_player=AudioStreamPlayer.new();effort_player.bus="SFX";add_child(effort_player)
	apply_volumes()
func start():
	started=true
	if ambience_target=="":change_ambience(game.level.stage_music() if game.level else 1)
	if ambience.stream and not ambience.playing:ambience.play()
func play(key,volume=0.0):
	var now=Time.get_ticks_msec()
	if key.begins_with("hit_") or key.begins_with("death_") or key=="shield_block":
		if now-int(recent_events.get(key,-1000))<65:return
		recent_events[key]=now
	if not bank.has(key):push_warning("Missing sound event: "+key);return
	play_one(key,volume-5,false)
	if key.begins_with("boss_warn_"):
		play_one("boss_warning_low",-13,true)
	elif key.begins_with("boss_") and key not in ["boss_death"]:
		play_one("boss_release",-10,true);impact_duck=maxf(impact_duck,3.5)
	elif key in ["boss_death","blast","sheep_blast"]:
		play_one("impact_heavy",-6,true);impact_duck=maxf(impact_duck,6.0)
	elif key in ["transform","brother_enter"]:
		play_one("transformation_surge",-10,true);impact_duck=maxf(impact_duck,3.0)

func play_one(key,volume,use_layer):
	var pool=layer_players if use_layer else players
	var available=null
	for p in pool:
		if not p.playing:available=p;break
	if available==null:return
	available.stream=bank[key];available.volume_db=volume
	available.pitch_scale=randf_range(.94,1.06) if key.begins_with("hit") or key.begins_with("step") else 1.0
	available.play()
func enemy_cue(identity,stage,volume=0.0):
	var profile=ENEMY_AUDIO.profiles().get(identity,{})
	if not profile.has(stage):return false
	return physical_cue(profile[stage],stage,volume)
func physical_cue(key,stage,volume=0.0):
	if not bank.has(key):return false
	var now=Time.get_ticks_msec()
	var interval=140 if stage=="release" else 55
	if key=="knight_gallop":interval=18
	if now-int(enemy_recent.get(key,-1000))<interval:return true
	enemy_recent[key]=now
	var pool=hurt_players if stage=="impact" else (warning_players if stage=="warning" else enemy_players)
	var voice=null
	for candidate in pool:
		if not candidate.playing:voice=candidate;break
	if voice==null:
		voice=pool[0]
		for candidate in pool:
			if candidate.get_playback_position()>voice.get_playback_position():voice=candidate
	voice.stop();voice.stream=bank[key];voice.pitch_scale=1.0
	voice.volume_db={"warning":-11.0,"charge":-13.0,"release":-5.0,"impact":-1.0,"landing":-7.0,"recover":-13.0}.get(stage,-8.0)+volume;voice.play()
	if stage=="impact":impact_duck=maxf(impact_duck,5.0)
	enemy_history.append(key)
	if enemy_history.size()>64:enemy_history.pop_front()
	return true
func exertion(boss):
	# Short efforts never interrupt dialogue or create subtitles; at most one every 800ms.
	var now=Time.get_ticks_msec()
	if now-effort_last<800 or (voice_player and voice_player.playing):return false
	# Pick any recorded shout of this boss except the one heard last.
	var keys=BOSS_DIALOGUE.BOSSES.get(boss,{}).get("efforts",{}).keys().map(func(line):return boss+"_"+line).filter(func(key):return ResourceLoader.exists("res://assets/voice/ai/"+key+".wav"))
	if keys.is_empty():return false
	var fresh=keys.filter(func(key):return effort_history.is_empty() or key!=effort_history[-1])
	var key=(fresh if not fresh.is_empty() else keys).pick_random()
	var path="res://assets/voice/ai/"+key+".wav"
	effort_last=now
	effort_player.stream=load(path);effort_player.volume_db=-7;effort_player.pitch_scale=1.0;effort_player.play()
	effort_history.append(key)
	if effort_history.size()>24:effort_history.pop_front()
	return true
func change_music(level,boss):
	# Scene music is separate from the reused environment art.
	if game.level and level==game.level.number:level=game.level.stage_music()
	change_ambience(clampi(level,1,3))
	var path="res://assets/music/level"+str(level)+("_boss.ogg" if boss else "_explore.ogg")
	if path==music_target:return
	var stream=load(path) as AudioStreamOggVorbis
	if stream==null:
		push_error("Cannot load scene score: "+path);return
	music_target=path;selected=1-selected;fade=0
	stream.loop=true;music_players[selected].stream=stream;music_players[selected].volume_db=-60;music_players[selected].play()

func change_ambience(level):
	var path="res://assets/audio/ambience_stage"+str(clampi(level,1,3))+".wav"
	if path==ambience_target:return
	ambience_target=path;ambience_selected=1-ambience_selected;ambience_fade=0
	var stream=load(path) as AudioStreamWAV
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_end=stream.data.size()/2
	var next=ambience_players[ambience_selected]
	next.stream=stream;next.volume_db=-60
	if started:next.play()
	ambience=next
func _process(dt):
	if audition_active:
		if game.state!="settings":stop_audition()
		else:
			audition_age+=dt
			while not audition_events.is_empty() and audition_events[0].at<=audition_age:
				var event=audition_events.pop_front();melee_sound(event.family,event.combo,-5.0 if event.family=="swing" else -3.0)
			if audition_age>6.5:stop_audition()
	duck_db=lerpf(duck_db,6.0 if audition_active or (voice_player and voice_player.playing) else 0.0,1-exp(-dt*10))
	impact_duck=maxf(0,impact_duck-dt*11.0)
	if voice_preview and game.state!="settings":
		voice_player.stop();voice_preview=false
	# Only write stream_paused when it changes: on the web build every un-pause restarts a sample
	# from its first frame, so writing it each frame kept voice lines stuck at their opening click.
	if effort_player:set_paused(effort_player,not game.active())
	if voice_player:
		var death_remark=game.state=="dead" and voice_identity.begins_with("lion_player_death")
		set_paused(voice_player,not game.active() and game.state!="boss_cinematic" and not (voice_preview and game.state=="settings") and not death_remark)
	fade=minf(1,fade+dt/.9)
	for i in 2:
		var gain=fade if i==selected else 1-fade
		music_players[i].volume_db=linear_to_db(maxf(.001,gain))-5-duck_db-impact_duck
		if gain==0 and i!=selected:music_players[i].stop()
	ambience_fade=minf(1,ambience_fade+dt/1.8)
	for i in 2:
		var gain=ambience_fade if i==ambience_selected else 1-ambience_fade
		ambience_players[i].volume_db=linear_to_db(maxf(.001,gain))-9
		if gain==0 and i!=ambience_selected:ambience_players[i].stop()
func set_paused(player,paused):
	if player.stream_paused!=paused:player.stream_paused=paused
func apply_volumes():
	if not game:return
	for pair in [["music","Music"],["sfx","SFX"],["ambience","Ambience"]]:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(pair[1]),linear_to_db(maxf(.001,game.progress[pair[0]])))
	muted=game.progress.muted;AudioServer.set_bus_mute(0,muted)
func toggle_mute():game.progress.muted=not game.progress.muted;apply_volumes();game.save_progress()

func is_boss_voice(key):
	for prefix in ["lantern_","duelist_","priest_","knight_","lion_"]:
		if key.begins_with(prefix):return true
	return false
func preview_boss_voice():
	var sample="knight_intro"
	if is_instance_valid(game.boss):
		var boss_id="lion" if game.boss.spec.id=="lion_elder" else game.boss.spec.id
		var bank=BOSS_DIALOGUE.BOSSES.get(boss_id,{})
		var lines=bank.get("groups",{}).get("intro",[])
		if not lines.is_empty():sample=boss_id+"_"+str(lines[0])
	return voice(sample,true)
func voice_path(key):
	var classic="res://assets/voice/"+key+".wav"
	var ai="res://assets/voice/ai/"+key+".wav"
	if is_boss_voice(key) and game.progress.get("boss_voice","ai")=="ai" and ResourceLoader.exists(ai):return ai
	return classic
func voice(key,preview=false):
	var path=voice_path(key)
	if not ResourceLoader.exists(path):return false
	var stream=load(path)
	if not stream:return false
	voice_player.stop();voice_identity=key;voice_source="ai" if "/ai/" in path else "classic";voice_preview=preview
	voice_player.stream=stream;voice_player.pitch_scale=1.0;voice_player.volume_db=-2 if voice_source=="ai" else 0;voice_player.stream_paused=false;voice_player.play()
	return true
func stop_all():
	if effort_player:effort_player.stop()
	voice_preview=false
	audition_active=false;audition_events.clear()
	if voice_player:voice_player.stop();voice_player.stream=null
	for p in players+layer_players+melee_players+enemy_players+warning_players+hurt_players+music_players+ambience_players:
		p.stop();p.stream=null
func _exit_tree():stop_all()

func melee_swing(combo):
	melee_sound("swing",combo,-5.0)
func melee_contact(surface,combo):
	melee_sound(surface,combo,-3.0)
func melee_sound(family,combo,volume):
	combo=clampi(combo,1,3)
	var group=family+str(combo);var previous=int(last_variant.get(group,-1))
	var choices=[0,1,2];choices.erase(previous)
	var variant=choices[randi()%choices.size()];last_variant[group]=variant
	var key="melee_"+group+"_"+str(variant)
	var available=melee_players[0]
	for player in melee_players:
		if not player.playing:available=player;break
		if player.get_playback_position()>available.get_playback_position():available=player
	available.stop();available.stream=bank[key];available.pitch_scale=1.0;available.volume_db=volume;available.play()
	if family=="swing" and combo==3:play_one("blade_air_heavy",-11,true)
	if family in ["stone","boss"] and combo==3:
		play_one("impact_heavy",-10,true);impact_duck=maxf(impact_duck,2.5)
	melee_history.append(key)
	if melee_history.size()>16:melee_history.pop_front()

func start_audition():
	if audition_active:stop_audition();return
	audition_age=-.2;audition_active=true;audition_events.clear()
	for group in 4:
		for index in 3:
			var hit=group*1.7+[0.0,.27,.56][index]+[.15,.17,.22][index]
			audition_events.append({"at":hit-SWING_LEAD[index],"family":"swing","combo":index+1})
			if group>0:audition_events.append({"at":hit,"family":["","soft","stone","block"][group],"combo":index+1})
	audition_events.sort_custom(func(a,b):return a.at<b.at)
func stop_audition():
	audition_active=false;audition_events.clear()
	for player in melee_players:player.stop()
func audition_label():
	return "停止试听 · "+["挥空","肉身","石甲","格挡"][clampi(int(audition_age/1.7),0,3)] if audition_active else "普通攻击试听"
