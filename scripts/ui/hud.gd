extends CanvasLayer
const COMBAT_ART=preload("res://scripts/ui/combat_hud_art.gd")
var game
var canvas
var buttons=[]
var pad_focus=0
var pad_state=""
var backdrop:Texture2D
var vistas:Texture2D
var hero:Texture2D
var niu:Texture2D
var niu_region=Rect2()
var settings_return="title"
var controls_return="title"
var stage_select_return="title"
var relic_journal_return="title"
var journey_records_return="title"
var journey_records_mode="standard"
var new_confirm_return="title"
var resource_feedback=0.0
var hovered_action=""
# Trailing boss health: lost health lingers as a pale band before draining.
var boss_lag=1.0
var boss_lag_hold=0.0
var boss_lag_owner=0
var boss_last_ratio=1.0
var player_lag=1.0
var player_lag_hold=0.0
var player_last_ratio=1.0
const HUD_BOUNDS=Rect2(0,0,960,540)
func _ready():
	layer=20;canvas=Node2D.new();add_child(canvas);canvas.draw.connect(render)
	canvas.material=ShaderMaterial.new();canvas.material.shader=load("res://scripts/actors/chroma.gdshader")
	vistas=load("res://assets/art/environment/vistas.png")
	backdrop=load("res://assets/art/moon_shrine.png");hero=load("res://assets/art/v2/hero.png");niu=load("res://assets/art/v3/bull.png")
	var bull=load("res://scripts/actors/atlas_actor.gd").new();bull.configure("res://assets/art/v3/bull.png",4,2,62)
	niu_region=Rect2(bull.regions[0].position+Vector2(bull.bounds[0].position),Vector2(bull.bounds[0].size));bull.free()
	# Background uses a separate layer below world entities.
	var back_layer=CanvasLayer.new();back_layer.layer=-10;add_child(back_layer)
	var back=Node2D.new();back_layer.add_child(back);back.draw.connect(draw_background)
	back.set_meta("background",true)
func _process(_dt):
	if game.active() and game.hitstop<=0:resource_feedback=maxf(0,resource_feedback-_dt)
	if is_instance_valid(game.boss) and game.state=="playing" and game.hitstop<=0:
		var ratio=clampf(game.boss.hp/game.boss.max_hp,0,1)
		if boss_lag_owner!=game.boss.get_instance_id() or ratio<boss_last_ratio:boss_lag_hold=.45
		boss_last_ratio=ratio
		if boss_lag_owner!=game.boss.get_instance_id() or ratio>boss_lag:boss_lag=ratio;boss_lag_owner=game.boss.get_instance_id()
		elif boss_lag>ratio:
			boss_lag_hold-=_dt
			if boss_lag_hold<=0:boss_lag=move_toward(boss_lag,ratio,_dt*.45)
		if absf(boss_lag-ratio)<.001:boss_lag_hold=.45
	if is_instance_valid(game.player) and game.active() and game.hitstop<=0:
		var health_ratio=clampf(game.player.health/100.0,0,1)
		if health_ratio<player_last_ratio:player_lag_hold=.32
		if health_ratio>player_lag:player_lag=health_ratio
		elif player_lag>health_ratio:
			player_lag_hold=maxf(0,player_lag_hold-_dt)
			if player_lag_hold==0:player_lag=move_toward(player_lag,health_ratio,_dt*.65)
		player_last_ratio=health_ratio
	var hovered=""
	if not game.pad_mode and not game.keyboard_nav:
		var pointer=canvas.get_global_mouse_position()
		for b in buttons:
			if b.rect.has_point(pointer):hovered=b.action;break
	if hovered!=hovered_action:
		if not hovered.is_empty():game.audio.play("ui_focus",-17)
		hovered_action=hovered
	canvas.queue_redraw()
	for c in get_children():
		if c is CanvasLayer:c.get_child(0).queue_redraw()
func draw_background():
	var b:Node2D=null
	for c in get_children():
		if c is CanvasLayer:b=c.get_child(0)
	if not b:return
	var stage=game.level.stage_art() if game.level else 1
	var px=game.player.position.x if is_instance_valid(game.player) else 0.0
	var section=clampi(int(px/4000),0,3)
	var index=stage-1
	if stage==1 and section==1:index=3
	var source=Rect2((index%2)*768,(index/2)*512,768,512)
	var drift=sin(px/2800.0)*24
	b.draw_texture_rect_region(vistas,Rect2(-40+drift,-25,1040,600),source,[Color(.53,.60,.69),Color(.48,.60,.60),Color(.56,.51,.65)][stage-1])
	# A low-contrast veil separates decorative detail from the playable plane.
	b.draw_rect(Rect2(0,0,960,540),[Color(.06,.10,.16,.13),Color(.07,.14,.15,.17),Color(.10,.07,.16,.15)][stage-1])
	if game.boss_rush:preload("res://scripts/world/battle_architecture.gd").backdrop(b,game)
	draw_stage_atmosphere(b,stage,px)
	# Fade foreground separation into the distance instead of a hard horizon band.
	b.draw_polygon(PackedVector2Array([Vector2(0,240),Vector2(960,240),Vector2(960,540),Vector2(0,540)]),PackedColorArray([Color(.025,.045,.075,0),Color(.025,.045,.075,0),Color(.025,.045,.075,.22),Color(.025,.045,.075,.22)]))

func draw_stage_atmosphere(b,stage,px):
	var t=game.ambience_clock
	match stage:
		1:
			# Two broken, high cloud wisps leave the walking plane untouched.
			for row in 2:
				var y=92+row*58+sin(t*.18+row)*5
				var offset=fposmod(t*(4+row)+px*.006+row*310,1120)-100
				for part in 3:
					var x=offset+part*165
					var points=PackedVector2Array()
					for i in 7:points.append(Vector2(x+i*18,y+sin(i*.9+row)*2))
					b.draw_polyline(points,Color(.52,.61,.70,.07),2)
		2:
			# Broad mist bands drift at different speeds and stay behind the piers.
			for row in 3:
				var base_y=250+row*64
				var points=PackedVector2Array()
				for i in 13:
					var x=-70+i*92
					var y=base_y+sin(i*.72+t*(.20+row*.04)+px*.0008)*7
					points.append(Vector2(x,y))
				b.draw_polyline(points,Color(.46,.64,.62,.055-row*.008),8-row*1.5)
		3:
			# Sparse bell dust and two dim shafts identify the altar without outlining hazards.
			for shaft in 2:
				var x=330+shaft*280+sin(t*.12+shaft)*18
				b.draw_colored_polygon(PackedVector2Array([Vector2(x-24,70),Vector2(x+18,70),Vector2(x+78,470),Vector2(x+12,470)]),Color(.47,.42,.62,.025))
			for i in 7:
				var x=170+posmod(i*127+31,650)+sin(t*.27+i)*7
				var y=120+fposmod(i*67+t*(3+i%2),300)
				b.draw_circle(Vector2(x,y),.8,Color(.61,.56,.70,.10))

func text(p,message,size=15,color=Color("eeeade")):
	if game.pad_mode:
		for pair in [["A D 移动","左摇杆移动"],["空格跳跃",game.gamepad.binding_label("jump")+" 跳跃"],["J 连按",game.gamepad.binding_label("attack")+" 连按"],["K 射箭",game.gamepad.binding_label("bow")+" 射箭"],["E 召唤",game.gamepad.binding_label("summon")+" 召唤"],["按住 U","按住 "+game.gamepad.binding_label("charge")],["按 Q","按 "+game.gamepad.binding_label("transform")],["Q  羊灵",game.gamepad.binding_label("transform")+" 羊灵"],["↑月露",game.gamepad.binding_label("item")+" 月露"]]:message=message.replace(pair[0],pair[1])
	canvas.draw_string(game.font,p,message,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func centered(y,message,size=17,color=Color("eeeade")):
	var w=game.font.get_string_size(message,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x;text(Vector2((960-w)/2,y),message,size,color)
func panel(rect,color=Color(.03,.055,.085,.93)):
	var style=StyleBoxFlat.new();style.bg_color=color;style.border_color=Color(.45,.62,.61,.4);style.set_border_width_all(1);style.set_corner_radius_all(4);canvas.draw_style_box(style,rect)
func button(rect,label,action,primary=false):
	var hovered=rect.has_point(canvas.get_global_mouse_position()) and not game.pad_mode and not game.keyboard_nav
	panel(rect,Color("ddbd89") if primary and hovered else (Color("c6a574") if primary else (Color("294955") if hovered else Color("152936"))))
	if hovered:canvas.draw_line(rect.position+Vector2(8,rect.size.y-1),rect.end-Vector2(8,1),game.TEAL,1)
	var size=16 if rect.size.y>34 else 12
	var width=game.font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	text(rect.position+Vector2((rect.size.x-width)*.5,rect.size.y*.5+size*.36),label,size,Color("13232b") if primary else game.WHITE)
	if (game.pad_mode or game.keyboard_nav) and game.state!="playing" and buttons.size()==pad_focus:
		canvas.draw_rect(rect.grow(3),game.GOLD,false,2)
	buttons.append({"rect":rect,"action":action,"label":label,"text_size":size})
func bottle(at,full):
	COMBAT_ART.bottle(canvas,at,full)
func gourd(at,color):
	canvas.draw_circle(at+Vector2(0,-5),4.5,color);canvas.draw_circle(at+Vector2(0,4),7,color)
	canvas.draw_line(at+Vector2(0,-10),at+Vector2(2,-13),Color("6b4f33"),2)
func meter(p,w,value,color):
	canvas.draw_rect(Rect2(p,Vector2(w,5)),Color("283c49"));canvas.draw_rect(Rect2(p,Vector2(w*clampf(value,0,1),5)),color)
func render():
	if pad_state!=game.state:pad_state=game.state;pad_focus=0
	buttons.clear()
	match game.state:
		"title":title_screen()
		"new_confirm":new_confirm_screen()
		"settings":settings_screen()
		"controls":controls_screen()
		"stage_select":stage_select_screen()
		"relic_journal":relic_journal_screen()
		"journey_records":journey_records_screen()
		"story":story_screen()
		"upgrade":upgrade_screen()
		"boss_cinematic":moon_cinematic()
		"animation_lab":animation_screen()
		_:
			if game.player and game.state=="playing":playing_hud()
			if game.state in ["paused","dead","stage_clear","win"]:overlay()
func title_screen():
	canvas.draw_rect(Rect2(0,0,960,540),Color(.02,.04,.07,.65))
	var safe_rect=safe_rect_in_hud() if game.is_touch else HUD_BOUNDS
	var title_x=touch_title_left_x(safe_rect) if game.is_touch else 70.0
	canvas.draw_line(Vector2(title_x,89),Vector2(title_x+45,89),game.GOLD,2)
	text(Vector2(maxf(title_x-6,safe_rect.position.x+16),179),"羊小侠",64)
	var touch_height=44 if game.is_touch else 34
	if game.has_journey_progress():
		button(Rect2(title_x,239,250,46),"继续连战","continue",true)
		button(Rect2(title_x,300,250,44 if game.is_touch else 40),"开启新旅途","new")
	else:
		button(Rect2(title_x,239,250,46),"五境连战","new",true)
	button(Rect2(title_x,356,120,touch_height),"选择关卡","stage_select")
	button(Rect2(title_x+130,356,120,touch_height),"设置","settings")
	var challenge_button_y=touch_menu_row_y(safe_rect,442,44) if game.is_touch else 446
	var challenge_shift=442-challenge_button_y if game.is_touch else 0
	panel(Rect2(title_x,413-challenge_shift,250,73 if game.is_touch else 66),Color(.025,.045,.065,.75))
	text(Vector2(title_x+15,(430 if game.is_touch else 436)-challenge_shift),"断誓骑场",12,game.GOLD)
	button(Rect2(title_x+15,challenge_button_y,101,44 if game.is_touch else 25),"马战","challenge")
	button(Rect2(title_x+130,challenge_button_y,105,44 if game.is_touch else 25),"步战","challenge_foot")
	# Bottom row is right-aligned so hiding the moon journal leaves no gap.
	var row=[["旅途簿","journey_records",90],["操作","controls",90],["参数 · F2","debug",110]]
	if game.relic_count()>0:row.push_front(["月痕札记","relic_journal",110])
	var row_height=44 if game.is_touch else 28
	var row_y=touch_menu_row_y(safe_rect,486,row_height) if game.is_touch else 486
	var portrait_feet=touch_title_portrait_feet(row_y) if game.is_touch else 453.0
	portrait(niu,niu_region,Vector2(713,portrait_feet),190)
	portrait(hero,Rect2(0,0,181,208),Vector2(550,portrait_feet),166)
	var x=touch_title_footer_right(safe_rect) if game.is_touch else 860.0
	for i in range(row.size()-1,-1,-1):
		x-=row[i][2];button(Rect2(x,row_y,row[i][2],row_height),row[i][0],row[i][1]);x-=10
	if game.developer_mode:
		var lab_button=touch_developer_button_rect(safe_rect) if game.is_touch else Rect2(818,20,122,28)
		button(lab_button,"动画对比","animation_lab")

func new_confirm_screen():
	canvas.draw_rect(Rect2(0,0,960,540),Color(.012,.026,.042,.94))
	panel(Rect2(200,150,560,245))
	centered(211,"重新出发？",30,game.GOLD)
	centered(258,"当前旅途进度将被覆盖。",16)
	centered(287,"月痕、纪录与设置会保留。",13,game.TEAL)
	var action_height=44 if game.is_touch else 42
	button(Rect2(235,328,230,action_height),"返回","new_confirm_back",true)
	button(Rect2(495,328,230,action_height),"重新出发","new_confirm_start")

func portrait(texture,source,feet,height):
	var size=Vector2(source.size.x/source.size.y*height,height)
	canvas.draw_texture_rect_region(texture,Rect2(feet-Vector2(size.x*.5,size.y),size),source)
func playing_hud():
	var p=game.player
	var status_offset=touch_status_offset(safe_rect_in_hud()) if game.is_touch else Vector2.ZERO
	panel(Rect2(Vector2(18,15)+status_offset,Vector2(236,48)),Color(.035,.055,.068,.88))
	canvas.draw_line(Vector2(27,16)+status_offset,Vector2(245,16)+status_offset,Color("b99b69",.45),1)
	text(Vector2(28,31)+status_offset,"血量 "+str(ceili(p.health))+" / 100",10,Color("ebc5b2"))
	text(Vector2(28,52)+status_offset,"战意 "+str(roundi(p.rage)),10,Color("d9c399"))
	COMBAT_ART.bar(canvas,Rect2(Vector2(108,22)+status_offset,Vector2(132,10)),p.health/100.0,Color("bc6d5e"),player_lag)
	COMBAT_ART.bar(canvas,Rect2(Vector2(108,43)+status_offset,Vector2(132,9)),p.rage/100.0,Color("b99a57"))
	var boost="×%.3f"%p.damage_multiplier()
	var boost_width=game.font.get_string_size(boost,HORIZONTAL_ALIGNMENT_LEFT,-1,9).x
	text(Vector2(239-boost_width,51)+status_offset,boost,9,Color("f4e4c5"))
	if p.health<=25:canvas.draw_line(Vector2(27,61)+status_offset,Vector2(245,61)+status_offset,Color("d7836c",.4+.15*sin(p.anim_clock*4)),1)
	if p.rage>=99.5:canvas.draw_line(Vector2(109,54)+status_offset,Vector2(239,54)+status_offset,Color("e7cf8c",.45+.2*sin(p.anim_clock*4)),1)
	if game.relaxed_journey():canvas.draw_circle(Vector2(248,20)+status_offset,2.5,game.TEAL)
	var tonic_rect=Rect2(Vector2(264,15)+status_offset,Vector2(58,48))
	button(tonic_rect,"","tonic")
	text(Vector2(273,28)+status_offset,"月露",10,Color("b4cebf"))
	for i in game.TONIC_MAX:
		bottle(Vector2(282+i*22,47)+status_offset,i<game.tonic_count())
	if resource_feedback>0:
		var tint=Color(1,.62,.35,resource_feedback*.8)
		canvas.draw_rect(tonic_rect.grow(2),tint,false,2)
		canvas.draw_rect(Rect2(Vector2(18,15)+status_offset,Vector2(236,48)).grow(2),tint,false,1)
	if p.hurt_anim>0:
		var hit_alpha=(1-smoothstep(0,.22,.22-p.hurt_anim))*.65
		for edge in [Rect2(0,0,960,4),Rect2(0,536,960,4),Rect2(0,0,4,540),Rect2(956,0,4,540)]:canvas.draw_rect(edge,Color(1,.38,.24,hit_alpha))
	# The stage name appears briefly when a fight starts, instead of a fixed panel.
	var banner=game.ambience_clock-game.stage_banner
	if banner>=0 and banner<2.4:
		var fade=smoothstep(0,.3,banner)*(1-smoothstep(1.7,2.4,banner))
		# Mid-screen title card between two thin rules, clear of the boss bar.
		var rise=(1-smoothstep(0,.4,banner))*8
		var half=60+smoothstep(0,.5,banner)*70
		canvas.draw_line(Vector2(480-half,214+rise),Vector2(480-28,214+rise),Color(game.GOLD,fade*.55),1)
		canvas.draw_line(Vector2(480+28,214+rise),Vector2(480+half,214+rise),Color(game.GOLD,fade*.55),1)
		canvas.draw_circle(Vector2(480,214+rise),2,Color(game.GOLD,fade*.8))
		centered(200+rise,game.level.title,30,Color(game.GOLD,fade))
		if game.boss_rush:centered(240+rise,"第 "+str(game.level.number)+" / 5 战",13,Color(game.TEAL,fade*.85))
	var quick_actions=[["跳","stage_select"],["调","debug"],["音","settings"],["Ⅱ","pause"]]
	if game.is_touch:
		var quick_rects=touch_quick_action_rects(safe_rect_in_hud())
		for i in quick_actions.size():button(quick_rects[i],quick_actions[i][0],quick_actions[i][1])
	else:
		for i in quick_actions.size():button(Rect2(785+i*41,15,33,25),quick_actions[i][0],quick_actions[i][1])
	if game.summon.unlocked:
		var summon=game.summon;var ally=summon.brother
		var icon=Vector2(37,84)+status_offset;var ready=summon.phase=="ready" and not summon.is_sealed()
		gourd(icon,Color("d8c08a") if ready else (Color("6c6a62") if summon.is_sealed() else Color("8f8a74")))
		if summon.is_sealed():
			canvas.draw_line(icon+Vector2(-8,-9),icon+Vector2(8,9),Color("d39283"),2)
			text(icon+Vector2(16,5),str(ceili(summon.seal_left())),12,Color("a7a39a"))
		elif summon.phase=="cooldown":text(icon+Vector2(16,5),str(ceili(summon.remaining)),12,Color("aab0a6"))
		elif ready:canvas.draw_arc(icon,13+sin(game.ambience_clock*3)*1.2,0,TAU,24,Color(game.GOLD,.45),1.2,true)
		if is_instance_valid(ally):
			COMBAT_ART.bar(canvas,Rect2(Vector2(56,82)+status_offset,Vector2(120,5)),ally.health/ally.max_health,Color("aeaa85"))
			text(Vector2(182,86)+status_offset,str(ceili(ally.health))+" / "+str(int(ally.max_health)),10,Color("c5d5b4"))
	var message_rect=touch_combat_message_rect(safe_rect_in_hud()) if game.is_touch else Rect2(200,493,560,30)
	if game.subtitle_time>0:
		panel(message_rect,Color(.025,.04,.055,.72));centered(message_rect.position.y+20,game.subtitle,14,game.GOLD)
	elif game.hint_time>0 and game.hint in ["获得月痕","出口已开启 →","闸门已开启","获得弓箭 · K 射击","生命已满","月露已用尽","葫芦尚未获得","尚未获得弓箭"]:
		centered(message_rect.position.y+(20 if game.is_touch else -3),game.hint.replace(" · K 射击",""),13,game.GOLD)
	if game.boss.active_battle and not game.boss.dead:
		var title_shadow=game.font.get_string_size(game.boss.spec.title,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x
		text(Vector2((960-title_shadow)*.5+1,137),game.boss.spec.title,15,Color("161725"))
		centered(136,game.boss.spec.title,15,game.GOLD)
		var title_width=game.font.get_string_size(game.boss.spec.title,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x
		for side in [-1,1]:
			var at=Vector2(480+side*(title_width*.5+18),131)
			canvas.draw_colored_polygon(PackedVector2Array([at+Vector2(-3,0),at+Vector2(0,-3),at+Vector2(3,0),at+Vector2(0,3)]),Color("b99b69"))
		var ratio=clampf(game.boss.hp/game.boss.max_hp,0,1)
		COMBAT_ART.bar(canvas,Rect2(290,148,380,10),ratio,Color("b56d65"),boss_lag)
		text(Vector2(290,175),"血量 "+str(ceili(game.boss.hp))+" / "+str(int(game.boss.max_hp)),10,Color("d2c3ae"))
		var percent=str(maxi(1,roundi(ratio*100)))+"%"
		text(Vector2(670-game.font.get_string_size(percent,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x,175),percent,10,Color("bca68b"))
	if game.boss.spec.id=="knight" and game.boss.active_battle and not game.boss.dead:
		for i in 3:
			var box=Rect2(414+i*46,184,34,8)
			canvas.draw_rect(box,Color(.08,.065,.12,.96))
			var fill=clampf(game.boss.soul.rage-i,0,1)
			if fill>0:canvas.draw_rect(Rect2(box.position,Vector2(box.size.x*fill,box.size.y)),Color("ca9ef0"))
			canvas.draw_rect(box,Color("9d7ab8",.82),false,1.2)
	if p.soul_slow>0:
		var slow_rect=touch_soul_slow_rect(status_offset)
		meter(slow_rect.position,slow_rect.size.x,minf(p.soul_slow/7.0,1.0),Color("c8a3ef"))
	if game.is_touch and game.active():
		for b in touch_layout():
			var pressed=game.touch_ids.values().has(b.action)
			panel(b.rect,Color(.30,.22,.12,.9) if pressed else Color(.04,.08,.12,.75))
			var label_width=game.font.get_string_size(b.label,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
			text(Vector2(b.rect.position.x+(b.rect.size.x-label_width)*.5,b.rect.position.y+b.rect.size.y*.5+5),b.label,16,game.WHITE if pressed else game.GOLD)
func upgrade_screen():
	canvas.draw_rect(Rect2(0,0,960,540),Color(.015,.03,.05,.88))
	var safe_rect=safe_rect_in_hud() if game.is_touch else HUD_BOUNDS
	var content_shift=touch_upgrade_shift(safe_rect) if game.is_touch else 0.0
	centered(58-content_shift,"山 灯 共 鸣",14,game.TEAL)
	centered(108-content_shift,"选择一式武学",31,game.GOLD)
	var card_rects=touch_upgrade_card_rects(safe_rect,158-content_shift,292) if game.is_touch else [Rect2(55,158-content_shift,260,292),Rect2(350,158-content_shift,260,292),Rect2(645,158-content_shift,260,292)]
	var cards=[
		{"id":"blade","name":"破锋","mark":"刃","color":Color("d99b80"),"lines":["连斩与羊灵近战","伤害提高 15%"]},
		{"id":"spirit","name":"灵火","mark":"焰","color":Color("d6bc72"),"lines":["羊灵延长 2 秒","幽焰更快，伤害 +4"]},
		{"id":"brother","name":"同心","mark":"契","color":Color("82c6b2"),"lines":["普通、蓄力冲撞","伤害均提升 12%"]}
	]
	for i in cards.size():
		var card=cards[i];var rect=card_rects[i];var current=game.upgrade_level(card.id)
		panel(rect,Color(.035,.07,.095,.97))
		canvas.draw_circle(Vector2(rect.get_center().x,207-content_shift),27,Color(card.color,.15))
		centered_card(rect,216-content_shift,card.mark,24,card.color)
		centered_card(rect,266-content_shift,card.name,25,card.color)
		centered_card(rect,302-content_shift,str(current)+" → "+str(current+1),12,game.TEAL)
		centered_card(rect,344-content_shift,card.lines[0],14)
		centered_card(rect,370-content_shift,card.lines[1],14)
		button(Rect2(rect.position.x+30,394-content_shift,rect.size.x-60,44 if game.is_touch else 38),"领悟","upgrade_"+card.id,i==0)
func centered_card(rect,y,message,size,color=Color("eeeade")):
	var w=game.font.get_string_size(message,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	text(Vector2(rect.get_center().x-w*.5,y),message,size,color)
func overlay():
	buttons.clear()
	if game.state in ["stage_clear","win"]:
		result_overlay();return
	var rows=[]
	if not game.is_challenge():
		rows=[["设置","settings"]]
		if game.state=="dead" and game.boss_rush and game.level.boss_id=="knight" and game.rush_knight_foot():rows.push_front(["重新挑战马战","rush_mounted"])
		if game.state=="paused" and game.relic_count()>0:rows.append(["月痕札记 · "+str(game.relic_count())+" / 6","relic_journal"])
		rows.append(["自由跳关","stage_select"]);rows.append(["回到标题","title"])
	var safe_rect=safe_rect_in_hud() if game.is_touch else HUD_BOUNDS
	var row_height=44 if game.is_touch else 38
	var step=46.0 if rows.size()>3 else 52.0
	var content_bottom=442.0 if game.is_challenge() else 343.0+(rows.size()-1)*step+row_height
	if game.state=="paused":content_bottom=maxf(content_bottom,516.0)
	var content_shift=touch_overlay_shift(safe_rect,content_bottom) if game.is_touch else 0.0
	canvas.draw_rect(Rect2(0,0,960,540),Color(.015,.035,.055,.9))
	var titles={"paused":"稍作歇息","dead":"再走一程"}
	centered((148 if game.state=="dead" else 162)-content_shift,titles[game.state],34,game.GOLD)
	if game.state=="dead":
		var guide=game.death_guide()
		centered(187-content_shift,"败因 · "+guide.title,17)
		centered(225-content_shift,guide.tip,12,game.TEAL)
		if game.relaxed_journey():centered(270-content_shift,"从容同行 · 承受伤害 70%",11,Color("8fbfb5"))
	else:
		canvas.draw_line(Vector2(440,202-content_shift),Vector2(520,202-content_shift),game.TEAL,1)
		if game.relaxed_journey():centered(232-content_shift,"从容同行 · 承受伤害 70%",12,game.TEAL)
	var action={"paused":"resume","dead":"retry"}[game.state]
	button(Rect2(350,283-content_shift,260,45),{"paused":"继续战斗" if game.boss_rush else "继续旅途","dead":("重试步战" if game.challenge_entry_phase==2 else "重试马战") if game.is_challenge() else (("从步战继续" if game.level.boss_id=="knight" and game.rush_knight_foot() else "重试当前 BOSS") if game.boss_rush else "从山灯重试")}[game.state],action,true)
	if game.is_challenge():
		var challenge_height=44 if game.is_touch else 38
		var utility_height=44 if game.is_touch else 36
		var animation_y=472-content_shift
		var utility_y=398-content_shift
		button(Rect2(350,338-content_shift,260,challenge_height),"重新挑战马战" if game.challenge_entry_phase==2 else "挑战步战","challenge" if game.challenge_entry_phase==2 else "challenge_foot")
		button(Rect2(282,utility_y,125,utility_height),"设置","settings")
		button(Rect2(417,utility_y,125,utility_height),"自由跳关","stage_select")
		button(Rect2(552,utility_y,125,utility_height),"回到标题","title")
		if game.state=="paused":button(Rect2(touch_menu_left_x(safe_rect,35) if game.is_touch else 35,animation_y,260,44 if game.is_touch else 34),"切换旧版 2D" if game.use_skeletal else "切换新版骨骼","hero_animation")
		return
	# Secondary actions stack evenly below the primary button; optional rows leave no gap.
	for i in rows.size():button(Rect2(350,343+i*step-content_shift,260,row_height),rows[i][0],rows[i][1])
	if game.state=="paused":
		var animation_y=472-content_shift
		var animation_x=touch_overlay_toggle_x(safe_rect,343-content_shift,step,rows.size(),row_height,animation_y,44) if game.is_touch else 35
		button(Rect2(animation_x,animation_y,260,44 if game.is_touch else 34),"切换旧版 2D" if game.use_skeletal else "切换新版骨骼","hero_animation")
func result_overlay():
	canvas.draw_rect(Rect2(0,0,960,540),Color(.012,.028,.045,.94))
	var won=game.state=="win";var result=game.stage_result
	if game.boss_rush:rush_result();return
	if game.is_challenge():challenge_result(result);return
	centered(75,"此行，有你同行" if won else "山门已开",34,game.GOLD)
	centered(107,"三关旅途已经完成。" if won else "第 "+str(result.get("level",game.level.number))+" 关已经走完。",14,game.TEAL)
	panel(Rect2(105,132,750,190),Color(.025,.055,.075,.97))
	var labels=["旅途用时","总击败","区域肃清","武学层数"] if won else ["本次用时","本次击败","区域肃清","武学精进"]
	var values=[format_time(game.elapsed),str(game.kills),str(game.journey_clears.size())+" / 12",str(game.progress.get("upgrades",[]).size())] if won else [format_time(result.get("seconds",0)),str(result.get("kills",0)),str(result.get("clears",0))+" / 4","+"+str(result.get("upgrades",0))]
	for i in 4:
		var x=135+i*185
		text(Vector2(x,174),labels[i],12,Color("aebdc0"))
		text(Vector2(x,219),values[i],26,game.GOLD if i in [0,2] else game.WHITE)
		if i<3:canvas.draw_line(Vector2(x+145,158),Vector2(x+145,246),Color(.35,.5,.52,.25),1)
	var martial="破锋 "+str(game.upgrade_level("blade"))+" 层   ·   灵火 "+str(game.upgrade_level("spirit"))+" 层   ·   同心 "+str(game.upgrade_level("brother"))+" 层   ·   月痕 "+str(game.relic_count())+" / 6"
	centered(287,martial,14,game.TEAL)
	var action_height=44 if game.is_touch else 34
	var utility_height=44 if game.is_touch else 36
	var action_y=touch_menu_row_y(safe_rect_in_hud(),459,action_height) if game.is_touch else 459
	var utility_y=minf(409.0,action_y-utility_height-6) if game.is_touch else 409
	var primary_y=minf(350.0,utility_y-45) if game.is_touch else 350
	button(Rect2(350,primary_y,260,45),"重新启程" if won else "前往下一关", "new" if won else "next",true)
	button(Rect2(282,utility_y,125,utility_height),"设置","settings")
	button(Rect2(417,utility_y,125,utility_height),"旅途簿","journey_records")
	button(Rect2(552,utility_y,125,utility_height),"回到标题","title")
	button(Rect2(350,action_y,260,action_height),"自由跳关","stage_select")
func rush_result():
	if game.state=="stage_clear":
		# Between bosses: show the automatic reward and the restored tonic, then continue.
		var next=load("res://data/arenas/boss_"+str(game.level.number+1)+".tres")
		centered(118,game.level.title+" · 已破",34,game.GOLD)
		centered(160,"第 "+str(game.level.number)+" / 5 战",14,game.TEAL)
		panel(Rect2(230,188,500,110),Color(.025,.055,.075,.97))
		if game.rush_reward!="":
			centered(230,"自动习得「"+game.UPGRADE_NAMES[game.rush_reward]+"」· 第 "+str(game.upgrade_level(game.rush_reward))+" 层",18,game.WHITE)
		centered(268,"月露已补满 ×"+str(game.TONIC_MAX)+"   ·   生命恢复",15,game.TEAL)
		next_boss_silhouette(next.boss_id,Vector2(812,452),178)
		button(Rect2(350,330,260,45),"下一战 · "+next.title,"next",true)
		var title_y=touch_menu_row_y(safe_rect_in_hud(),395,44) if game.is_touch else 395
		button(Rect2(350,title_y,260,44 if game.is_touch else 38),"回到标题","title")
		return
	centered(138,"五境皆破",38,game.GOLD)
	centered(186,"守石 · 渡影 · 噬月 · 断誓 · 衔灯",17,game.TEAL)
	centered(244,format_time(game.elapsed)+"   ·   五战告捷",22)
	button(Rect2(350,320,260,45),"再战五境","new",true)
	var title_y=touch_menu_row_y(safe_rect_in_hud(),385,44) if game.is_touch else 385
	button(Rect2(350,title_y,260,44 if game.is_touch else 38),"回到标题","title")
# A dark silhouette of the coming boss teases the next fight without spelling it out.
func next_boss_silhouette(id,feet,height):
	var texture;var source
	if id=="lion_elder":
		# No stand-in portrait: the dedicated frames are supplied by the art task.
		text(feet+Vector2(-65,-height*.5),"衔灯狮叟",20,game.TEAL)
		return
	if id=="knight":
		texture=load("res://assets/art/knight_frames/mounted/00.png");source=Rect2(Vector2.ZERO,texture.get_size())
	else:
		# Per-frame boss art has a transparent background (frames 0/6/12 are each idle pose).
		texture=load("res://assets/art/boss_frames/%02d.png"%(["lantern","duelist","priest"].find(id)*6))
		source=Rect2(Vector2.ZERO,texture.get_size())
	var size=Vector2(source.size.x/source.size.y*height,height)
	var rect=Rect2(feet-Vector2(size.x*.5,size.y),size)
	var pulse=.5+.5*sin(game.clock*1.6)
	canvas.draw_texture_rect_region(texture,rect.grow(2),source,Color(.55,.85,.8,.10+.06*pulse))
	canvas.draw_texture_rect_region(texture,rect,source,Color(.02,.035,.05,.96))
	var boss=load("res://data/bosses/"+id+".tres")
	var w=game.font.get_string_size(boss.title,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
	text(Vector2(feet.x-w*.5,feet.y+22),boss.title,13,Color(game.TEAL,.8))
func challenge_result(result):
	var action_height=44 if game.is_touch else 34
	var action_y=touch_menu_row_y(safe_rect_in_hud(),439,action_height) if game.is_touch else 439
	var content_shift=439-action_y if game.is_touch else 0
	centered(75-content_shift,"步战已破" if result.get("practice",false) else "断誓已了",34,game.GOLD)
	centered(107-content_shift,game.boss.spec.title+(" · 步战演武完成" if result.get("practice",false) else " · 马战与步战均已击破"),14,game.TEAL)
	panel(Rect2(185,132-content_shift,590,170),Color(.025,.055,.075,.97))
	var record=game.stage_record(game.CHALLENGE_LEVEL,game.progress.get("journey_mode","standard"))
	var labels=["本次用时","最快用时","挑战完成"]
	var values=[format_time(result.get("seconds",0)),format_time(record.get("best_seconds",0)),str(record.get("completions",0))+" 次"]
	for i in 3:
		var x=215+i*190
		text(Vector2(x,174-content_shift),labels[i],12,Color("aebdc0"))
		text(Vector2(x,219-content_shift),values[i],26,game.GOLD if i==0 else game.WHITE)
		if i<2:canvas.draw_line(Vector2(x+160,158-content_shift),Vector2(x+160,246-content_shift),Color(.35,.5,.52,.25),1)
	centered(277-content_shift,"步战演武 · 不计完整双阶段纪录" if result.get("practice",false) else "独立挑战 · 不影响旅途进度",12,Color("aebdc0"))
	button(Rect2(350,330-content_shift,260,45),"再战一次","next",true)
	var utility_height=44 if game.is_touch else 36
	button(Rect2(282,389-content_shift,125,utility_height),"设置","settings")
	button(Rect2(417,389-content_shift,125,utility_height),"旅途簿","journey_records")
	button(Rect2(552,389-content_shift,125,utility_height),"回到标题","title")
	button(Rect2(350,action_y,260,action_height),"自由跳关","stage_select")
func format_time(seconds):
	var whole=maxi(0,int(seconds))
	return "%02d:%02d" % [whole/60,whole%60]
func relic_journal_rows():
	var rows=[];var collected=game.progress.get("relics",[])
	for i in game.RELIC_IDS.size():
		var id=game.RELIC_IDS[i];var parts=game.RELIC_TEXT[id].split(" · ")
		rows.append({"id":id,"number":i+1,"stage":int(id.get_slice("_",1)),"collected":id in collected,"name":parts[0],"body":parts[1]})
	return rows
func relic_journal_screen():
	canvas.draw_rect(Rect2(0,0,960,540),Color(.018,.038,.058,.99))
	centered(58,"月 痕 札 记",30,game.GOLD)
	centered(88,"已寻得 "+str(game.relic_count())+" / 6 · 月色会记住走过的路",13,game.TEAL)
	var rows=relic_journal_rows()
	var card_rects=touch_relic_journal_rects(safe_rect_in_hud()) if game.is_touch else []
	for i in rows.size():
		var row=rows[i];var rect=card_rects[i] if game.is_touch else Rect2(55+(i%2)*430,112+(i/2)*112,410,92)
		panel(rect,Color(.035,.072,.092,.98) if row.collected else Color(.025,.045,.06,.92))
		var icon=rect.position+Vector2(31,45);var color=game.GOLD if row.collected else Color("52636a")
		canvas.draw_arc(icon,14,-PI*.72,PI*.72,18,color,3)
		text(rect.position+Vector2(58,29),row.name if row.collected else "月痕之"+str(row.number),17,color)
		var stage_label="第 "+str(row.stage)+" 关";var stage_width=game.font.get_string_size(stage_label,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
		text(rect.position+Vector2(minf(314.0,rect.size.x-stage_width-16),28),stage_label,11,game.TEAL if row.collected else Color("68777b"))
		text(rect.position+Vector2(58,61),row.body if row.collected else "尚未寻得",12,game.WHITE if row.collected else Color("77868a"))
	var back_height=44 if game.is_touch else 38
	var back_y=touch_menu_row_y(safe_rect_in_hud(),468,back_height) if game.is_touch else 468
	button(Rect2(380,back_y,200,back_height),"返回","relic_journal_back",true)
func journey_record_rows():
	var rows=[]
	# Records follow all five rush battles.
	for number in range(1,game.RUSH_BATTLES+1):
		var stage=load("res://data/arenas/boss_"+str(number)+".tres")
		var boss=load("res://data/bosses/"+stage.boss_id+".tres")
		rows.append({"number":number,"title":stage.title,"boss":boss.title,"record":game.stage_record(number,journey_records_mode)})
	return rows
func journey_records_screen():
	canvas.draw_rect(Rect2(0,0,960,540),Color(.018,.038,.058,.99))
	centered(55,"旅 途 簿",30,game.GOLD)
	var tab_height=44 if game.is_touch else 34
	button(Rect2(340,97,135,tab_height),"标准记录","records_standard",journey_records_mode=="standard")
	button(Rect2(485,97,135,tab_height),"从容记录","records_relaxed",journey_records_mode=="relaxed")
	var rows=journey_record_rows()
	var card_rects=touch_journey_record_rects(safe_rect_in_hud()) if game.is_touch else []
	for i in rows.size():
		var row=rows[i];var rect=card_rects[i] if game.is_touch else Rect2(24+i*184,151,176,273);var record=row.record
		var done=not record.is_empty()
		panel(rect,Color(.035,.072,.092,.98) if done else Color(.025,.045,.06,.92))
		centered_card(rect,185,"第 "+str(row.number)+" 战",12,game.TEAL)
		centered_card(rect,220,row.title,18,game.GOLD if done else Color("8a8f86"))
		canvas.draw_line(rect.position+Vector2(20,88),rect.position+Vector2(rect.size.x-20,88),Color(.35,.55,.55,.3),1)
		centered_card(rect,262,row.boss,14,game.WHITE if done else Color("6f7d80"))
		if done:
			centered_card(rect,306,"最快  "+format_time(record.best_seconds),20,game.GOLD)
			centered_card(rect,340,"击破 "+str(record.completions)+" 次",13)
			# A simple seal marks a defeated boss.
			var seal=Vector2(rect.get_center().x,rect.end.y-32)
			canvas.draw_arc(seal,14,0,TAU,28,Color(game.GOLD,.7),2,true)
			canvas.draw_line(seal+Vector2(-6,0),seal+Vector2(-1,5),game.GOLD,2);canvas.draw_line(seal+Vector2(-1,5),seal+Vector2(7,-5),game.GOLD,2)
		else:
			centered_card(rect,320,"尚未击破",17,Color("7f9295"))
	var back_height=44 if game.is_touch else 38
	var back_y=touch_menu_row_y(safe_rect_in_hud(),466,back_height) if game.is_touch else 466
	button(Rect2(380,back_y,200,back_height),"返回","journey_records_back",true)
func stage_select_screen():
	canvas.draw_rect(Rect2(0,0,960,540),Color(.025,.045,.07,.98))
	centered(76,"自由跳关",30,game.GOLD)
	var action_x=touch_stage_select_button_x(safe_rect_in_hud()) if game.is_touch else 600.0
	for i in game.RUSH_BATTLES:
		var stage=load("res://data/arenas/boss_"+str(i+1)+".tres")
		var boss=load("res://data/bosses/"+stage.boss_id+".tres")
		var y=108+i*70
		# A cropped band of the arena's own vista identifies each fight at a glance.
		var index=stage.stage_art()-1
		var source=Rect2((index%2)*768,(index/2)*512+150,768,240)
		var thumb=Rect2(150,y,150,62)
		canvas.draw_texture_rect_region(vistas,thumb,source,Color(.8,.86,.92))
		canvas.draw_rect(thumb,Color(.45,.62,.61,.5),false,1)
		var cleared=i+1 in game.progress.get("rush_clears",[])
		text(Vector2(322,y+28),str(i+1)+" · "+stage.title,20,game.GOLD)
		text(Vector2(322,y+52),boss.title+("   · 已击破" if cleared else ""),13,game.TEAL if cleared else Color("9aa8aa"))
		button(Rect2(action_x,y+11,200,44 if game.is_touch else 40),"进入战场","jump_"+str(i+1)+"_0")
	var back_height=44 if game.is_touch else 38
	var back_y=touch_menu_row_y(safe_rect_in_hud(),473,back_height) if game.is_touch else 473
	button(Rect2(380,back_y,200,back_height),"返回","stage_select_back")
func settings_screen():
	canvas.draw_rect(Rect2(0,0,960,540),Color(.025,.045,.07,.98))
	centered(65,"设置",30,game.GOLD)
	var safe_rect=safe_rect_in_hud() if game.is_touch else HUD_BOUNDS
	var left_offset=touch_settings_left_offset(safe_rect) if game.is_touch else 0.0
	var right_offset=touch_settings_right_offset(safe_rect) if game.is_touch else 0.0
	var left_panel_x=70+left_offset;var left_panel_width=minf(390.0,490.0-left_panel_x)
	var right_panel_width=minf(400.0,safe_rect.end.x-16.0-490.0) if game.is_touch else 400.0
	panel(Rect2(left_panel_x,100,left_panel_width,325));panel(Rect2(490,100,right_panel_width,325))
	text(Vector2(100+left_offset,137),"声音",18,game.GOLD)
	var labels={"music":"音乐","sfx":"音效","ambience":"环境"}
	var index=0
	for key in labels:
		var y=160+index*57;text(Vector2(100+left_offset,y+24),labels[key],16)
		var volume_size=44 if game.is_touch else 36
		var volume_y=y-5 if game.is_touch else y
		button(Rect2((231 if game.is_touch else 235)+left_offset,volume_y,volume_size,44 if game.is_touch else 34),"−","volume_"+key+"_-1")
		text(Vector2(292+left_offset,y+24),str(int(game.progress[key]*100))+"%",16)
		button(Rect2((386 if game.is_touch else 390)+left_offset,volume_y,volume_size,44 if game.is_touch else 34),"＋","volume_"+key+"_1");index+=1
	var mute_y=329 if game.is_touch else 347
	var mute_height=44 if game.is_touch else 34
	var voice_y=381 if game.is_touch else 393
	var voice_height=44 if game.is_touch else 25
	button(Rect2(100+left_offset,mute_y,145,mute_height),"声音：关" if game.progress.muted else "声音：开","mute")
	button(Rect2(265+left_offset,mute_y,160,mute_height),"试听","melee_audition")
	button(Rect2(100+left_offset,voice_y,145,voice_height),"AI 配音","voice_ai",game.progress.get("boss_voice","ai")=="ai")
	button(Rect2(265+left_offset,voice_y,160,voice_height),"经典配音","voice_classic",game.progress.get("boss_voice","ai")=="classic")
	text(Vector2(520+right_offset,137),"旅途",18,game.GOLD)
	button(Rect2(520+right_offset,161,340,44 if game.is_touch else 38),"难度 · "+("从容" if game.relaxed_journey() else "标准"),"journey_mode")
	button(Rect2(520+right_offset,214,340,44 if game.is_touch else 34),"震动 · "+("开" if game.progress.screen_shake else "关"),"screen_shake")
	text(Vector2(520+right_offset,286),"角色外观",14,game.TEAL)
	button(Rect2(520+right_offset,303,160,44 if game.is_touch else 34),"骨骼动画","hero_modern",game.use_skeletal)
	button(Rect2(700+right_offset,303,160,44 if game.is_touch else 34),"经典 2D","hero_legacy",not game.use_skeletal)
	button(Rect2(520+right_offset,360,340,44 if game.is_touch else 34),"操作与按键","controls")
	var back_rect=touch_settings_back_rect(safe_rect_in_hud()) if game.is_touch else Rect2(380,465,200,40)
	button(back_rect,"返回","back",true)

func story_screen():
	canvas.draw_rect(Rect2(0,0,960,540),Color(.025,.045,.075,.9))
	var action_height=44 if game.is_touch else 38
	var action_y=touch_menu_row_y(safe_rect_in_hud(),459,action_height) if game.is_touch else 459
	var content_shift=459-action_y
	portrait(niu,niu_region,Vector2(630,315-content_shift),130)
	portrait(hero,Rect2(0,0,181,208),Vector2(350,315-content_shift),120)
	var lines=["牛大侠：前面的路更险了。把这个葫芦带上。","牛大侠：需要帮忙就唤我一声，我的牛角会替你开路。","羊小侠：那就一起走。哥，下一关见！"]
	panel(Rect2(155,340-content_shift,650,95));text(Vector2(180,377-content_shift),lines[game.story_page],16)
	button(Rect2(590,action_y,215,action_height),"继续  →","story_next",true);button(Rect2(155,action_y,145,action_height),"跳过剧情","story_skip")
static func safe_area_in_hud(screen_area:Rect2i,screen_to_hud:Transform2D):
	if screen_area.size.x<=0 or screen_area.size.y<=0:return HUD_BOUNDS
	var source=Rect2(screen_area.position,screen_area.size)
	var corners=[source.position,Vector2(source.end.x,source.position.y),source.end,Vector2(source.position.x,source.end.y)]
	var first=screen_to_hud*corners[0];var left=first.x;var right=first.x;var top=first.y;var bottom=first.y
	for corner in corners.slice(1):
		var point=screen_to_hud*corner
		left=minf(left,point.x);right=maxf(right,point.x);top=minf(top,point.y);bottom=maxf(bottom,point.y)
	var mapped=Rect2(Vector2(left,top),Vector2(right-left,bottom-top)).intersection(HUD_BOUNDS)
	return HUD_BOUNDS if mapped.size.x<=0 or mapped.size.y<=0 else mapped
static func touch_safe_shifts(safe_rect:Rect2):
	return Vector3(maxf(0,safe_rect.position.x+16-34),maxf(0,920-(safe_rect.end.x-16)),maxf(0,501-(safe_rect.end.y-16)))
static func touch_combat_message_rect(safe_rect:Rect2):
	var controls_up=touch_safe_shifts(safe_rect).z
	return Rect2(200,382-controls_up-42,560,30)
static func touch_menu_row_y(safe_rect:Rect2,base_y:float,row_height:float):
	return minf(base_y,safe_rect.end.y-row_height-16)
static func touch_overlay_shift(safe_rect:Rect2,content_bottom:float):
	return maxf(0.0,content_bottom-(safe_rect.end.y-16))
static func touch_overlay_toggle_x(safe_rect:Rect2,row_top:float,row_step:float,row_count:int,row_height:float,toggle_y:float,toggle_height:float):
	var left=maxf(35.0,safe_rect.position.x+16)
	var right=maxf(safe_rect.position.x+16,safe_rect.end.x-16-260)
	var left_clear=true;var right_clear=true
	for i in row_count:
		var row=Rect2(350,row_top+i*row_step,260,row_height)
		left_clear=left_clear and not Rect2(left,toggle_y,260,toggle_height).intersects(row)
		right_clear=right_clear and not Rect2(right,toggle_y,260,toggle_height).intersects(row)
	if left_clear:return left
	if right_clear:return right
	return right
static func touch_menu_left_x(safe_rect:Rect2,base_x:float):
	return maxf(base_x,safe_rect.position.x+16)
static func touch_status_offset(safe_rect:Rect2):
	return Vector2(maxf(0,safe_rect.position.x+16-18),maxf(0,safe_rect.position.y+16-15))
static func touch_soul_slow_rect(status_offset:Vector2):
	return Rect2(Vector2(30,69)+status_offset,Vector2(212,4))
static func touch_controls_row_xs(safe_rect:Rect2):
	var left=safe_rect.position.x+16;var right=safe_rect.end.x-16
	var gap_total=minf(95.0,maxf(0,right-left-715))
	var first_gap=gap_total*30.0/95.0;var second_gap=gap_total-first_gap
	var row_width=715+gap_total;var start=(left+right-row_width)*.5
	return [start,start+260+first_gap,start+260+first_gap+220+second_gap]
static func touch_animation_lab_xs(safe_rect:Rect2):
	var left=maxf(55,safe_rect.position.x+16);var right=minf(895,safe_rect.end.x-16)
	var gap_total=minf(130.0,maxf(0,right-left-710));var ratio=gap_total/130.0
	var gaps=[15*ratio,15*ratio,40*ratio,60*ratio]
	var x=[left]
	x.append(x[0]+110+gaps[0]);x.append(x[1]+125+gaps[1]);x.append(x[2]+110+gaps[2]);x.append(x[3]+235+gaps[3])
	return x
static func touch_animation_lab_layout(safe_rect:Rect2):
	var control_y=touch_menu_row_y(safe_rect,451,44)
	var shift=451-control_y
	return {"control_y":control_y,"shift":shift,"panel_bottom":400-shift,"preview_y":372-shift,"title_y":control_y-24,"footnote_y":104}
static func touch_upgrade_shift(safe_rect:Rect2):
	return maxf(0.0,450.0-(safe_rect.end.y-16.0))
static func touch_upgrade_card_rects(safe_rect:Rect2,top:float,height:float):
	var left=maxf(55.0,safe_rect.position.x+16)
	var right=minf(905.0,safe_rect.end.x-16)
	var available=right-left
	var gap=minf(35.0,maxf(12.0,(available-780.0)*.5))
	var width=(available-gap*2)/3.0
	var rects=[]
	for i in 3:rects.append(Rect2(left+i*(width+gap),top,width,height))
	return rects
static func touch_title_left_x(safe_rect:Rect2):
	return maxf(70.0,safe_rect.position.x+16)
static func touch_title_footer_right(safe_rect:Rect2):
	return minf(860.0,safe_rect.end.x-16)
static func touch_title_portrait_feet(footer_y:float):
	return minf(453.0,footer_y-8.0)
static func touch_developer_button_rect(safe_rect:Rect2):
	var left=safe_rect.position.x+16
	var right=safe_rect.end.x-16-122
	return Rect2(maxf(left,minf(818.0,right)),maxf(12.0,safe_rect.position.y+16),122,44)
static func touch_settings_left_offset(safe_rect:Rect2):
	return maxf(0.0,safe_rect.position.x+16.0-70.0)
static func touch_settings_right_offset(safe_rect:Rect2):
	return minf(0.0,safe_rect.end.x-16.0-860.0)
static func touch_controls_help_ys(action_y:float):
	return Vector2(action_y-52,action_y-24)
static func touch_controls_columns(safe_rect:Rect2):
	var left=maxf(80.0,safe_rect.position.x+16)
	var right=minf(865.0,safe_rect.end.x-16)
	var span=right-left
	var gap=clampf(span-730.0,16.0,55.0)
	var column_width=(span-gap)/2.0
	return [left,left+column_width+gap,maxf(44.0,minf(175.0,column_width-190.0))]
static func touch_stage_select_button_x(safe_rect:Rect2):
	return minf(600.0,safe_rect.end.x-16.0-200.0)
static func touch_relic_journal_rects(safe_rect:Rect2):
	var action_y=touch_menu_row_y(safe_rect,468,44)
	var cards_bottom=minf(428.0,action_y-12.0)
	var row_height=minf(92.0,maxf(60.0,(cards_bottom-112.0-24.0)/3.0))
	var row_gap=(cards_bottom-112.0-row_height*3)/2.0
	var left=maxf(55.0,safe_rect.position.x+16)
	var right=minf(905.0,safe_rect.end.x-16)
	var column_gap=20.0
	var card_width=minf(410.0,(right-left-column_gap)/2.0)
	var rects=[]
	for i in 6:rects.append(Rect2(left+(i%2)*(card_width+column_gap),112+(i/2)*(row_height+row_gap),card_width,row_height))
	return rects
static func touch_journey_record_rects(safe_rect:Rect2):
	var left=maxf(40.0,safe_rect.position.x+16)
	var right=minf(920.0,safe_rect.end.x-16)
	var gap=8.0
	var card_width=(right-left-gap*4)/5.0
	var rects=[]
	for i in 5:rects.append(Rect2(left+i*(card_width+gap),151,card_width,273))
	return rects
static func touch_settings_back_rect(safe_rect:Rect2):
	var back_y=touch_menu_row_y(safe_rect,465,44)
	var centered_back=Rect2(380,back_y,200,44)
	if centered_back.intersects(Rect2(100,381,325,44)) or centered_back.intersects(Rect2(520,360,340,44)):
		var gap_back=Rect2(426,back_y,94,44)
		if safe_rect.encloses(gap_back):return gap_back
	return centered_back
static func touch_quick_action_rects(safe_rect:Rect2):
	var width=44.0;var gap=4.0;var total_width=width*4+gap*3
	var right=minf(942.0,safe_rect.end.x-16)
	var left=maxf(safe_rect.position.x+16,right-total_width)
	var top=maxf(12.0,safe_rect.position.y+16)
	var rects=[]
	for i in 4:rects.append(Rect2(left+i*(width+gap),top,width,width))
	return rects
static func touch_layout_for_safe_rect(safe_rect:Rect2):
	var edge_inset=16.0;var shifts=touch_safe_shifts(safe_rect)
	var left=shifts.x;var right=shifts.y;var up=shifts.z
	return [{"rect":Rect2(18+edge_inset+left,440-up,48,48),"label":"←","action":"left"},{"rect":Rect2(74+edge_inset+left,440-up,48,48),"label":"→","action":"right"},{"rect":Rect2(130+edge_inset+left,440-up,48,48),"label":"↓","action":"down"},{"rect":Rect2(876-edge_inset-right,441-up,60,60),"label":"剑","action":"attack"},{"rect":Rect2(817-edge_inset-right,445-up,48,48),"label":"跳","action":"jump"},{"rect":Rect2(758-edge_inset-right,445-up,48,48),"label":"闪","action":"dash"},{"rect":Rect2(878-edge_inset-right,382-up,48,48),"label":"弓","action":"bow"},{"rect":Rect2(819-edge_inset-right,382-up,48,48),"label":"蓄","action":"charge"},{"rect":Rect2(760-edge_inset-right,382-up,48,48),"label":"羊","action":"transform"},{"rect":Rect2(701-edge_inset-right,445-up,48,48),"label":"兄","action":"summon"},{"rect":Rect2(701-edge_inset-right,382-up,48,48),"label":"露","action":"item"}]
func safe_rect_in_hud():
	var screen_area=DisplayServer.get_display_safe_area()
	return safe_area_in_hud(screen_area,canvas.get_screen_transform().affine_inverse())
func touch_layout():
	return touch_layout_for_safe_rect(safe_rect_in_hud())
func handle_click(at):
	if pad_state!=game.state:return false
	for b in buttons:
		if b.rect.has_point(at):action(b.action);return true
	return false
func action(id):
	game.audio.play("ui_back" if id in ["back","title","resume","new_confirm_back"] or id.ends_with("_back") else "ui_confirm",-5)
	if id.begins_with("bind_"):game.gamepad.rebinding=id.substr(5);return
	if id.begins_with("upgrade_"):game.choose_upgrade(id.substr(8));return
	if id.begins_with("jump_"):
		var parts=id.split("_");game.call_deferred("jump_to_stage",int(parts[1]),int(parts[2]));return
	if id.begins_with("volume_"):
		var parts=id.split("_");var key=parts[1];game.progress[key]=clampf(game.progress[key]+float(parts[2])*.1,0,1);game.audio.apply_volumes();game.save_progress();return
	match id:
		"relic_journal":relic_journal_return=game.state;game.state="relic_journal";game.release_inputs()
		"relic_journal_back":game.state=relic_journal_return
		"journey_records":journey_records_return=game.state;journey_records_mode=game.progress.get("journey_mode","standard");game.state="journey_records";game.release_inputs()
		"journey_records_back":game.state=journey_records_return
		"records_standard":journey_records_mode="standard"
		"records_relaxed":journey_records_mode="relaxed"
		"stage_select":stage_select_return=game.state;game.state="stage_select";game.release_inputs()
		"challenge":game.call_deferred("start_challenge")
		"challenge_foot":game.call_deferred("start_challenge",game.CHALLENGE_LEVEL,2)
		"stage_select_back":game.state=stage_select_return
		"debug":game.debug_panel.toggle()
		"animation_lab":game.open_animation_lab()
		"lab_back":game.state=game.animation_lab.previous
		"lab_pause":game.animation_lab.playing=not game.animation_lab.playing
		"lab_speed":game.animation_lab.speed=.5 if game.animation_lab.speed==1.0 else 1.0
		"lab_restart":game.animation_lab.restart()
		"lab_switch","hero_animation":
			game.set_hero_animation(not game.use_skeletal)
		"hero_modern":game.set_hero_animation(true)
		"hero_legacy":game.set_hero_animation(false)
		"new":
			if game.state=="title" and game.has_journey_progress():new_confirm_return="title";game.state="new_confirm";game.release_inputs()
			else:game.start_new()
		"new_confirm_start":game.start_new()
		"new_confirm_back":game.state=new_confirm_return;game.release_inputs()
		"continue":game.continue_game()
		"resume":game.resume_battle()
		"pause":game.state="paused";game.release_inputs()
		"retry":game.retry()
		"rush_mounted":game.retry_mounted()
		"next":game.next_level()
		"title":game.return_title()
		"settings":settings_return=game.state;game.state="settings";game.release_inputs()
		"controls":controls_return=game.state;game.state="controls";game.release_inputs()
		"controls_back":game.gamepad.rebinding="";game.state=controls_return
		"pad_reset":game.gamepad.reset_bindings()
		"pad_glyphs":
			var types=["auto","xbox","ps","switch"];game.gamepad.glyphs=types[(types.find(game.gamepad.glyphs)+1)%4];game.gamepad.save_bindings()
		"back":game.state=settings_return
		"mute":game.audio.toggle_mute()
		"voice_ai","voice_classic":
			game.progress.boss_voice="ai" if id=="voice_ai" else "classic";game.save_progress()
			game.audio.preview_boss_voice()
		"screen_shake":game.progress.screen_shake=not game.progress.screen_shake;game.save_progress()
		"journey_mode":game.progress.journey_mode="standard" if game.relaxed_journey() else "relaxed";game.save_progress()
		"melee_audition":game.audio.start_audition()
		"tonic":game.use_tonic()
		"story_next":game.advance_story()
		"story_skip":game.complete_story()

func pad_move(direction):
	if pad_state!=game.state:return
	if buttons.is_empty():return
	pad_focus=clampi(pad_focus,0,buttons.size()-1)
	var origin=buttons[pad_focus].rect.get_center()
	var best=-1;var score=INF
	for i in buttons.size():
		if i==pad_focus:continue
		var delta=buttons[i].rect.get_center()-origin
		var forward=delta.dot(direction)
		if forward<=1:continue
		var sideways=absf(delta.cross(direction))
		var value=forward+sideways*3
		if value<score:score=value;best=i
	if best<0:best=posmod(pad_focus+(1 if direction.x+direction.y>0 else -1),buttons.size())
	pad_focus=best;game.audio.play("ui_focus",-12)
func pad_activate():
	if pad_state!=game.state:return
	if buttons.is_empty():return
	var selected=buttons[clampi(pad_focus,0,buttons.size()-1)].action
	action(selected)

func animation_screen():
	canvas.draw_rect(Rect2(0,0,960,540),Color("111f2c"))
	centered(55,"羊小侠 · 连续动作样片",27,game.GOLD)
	centered(86,"同一原画，左侧切换姿势，右侧二维网格补间",13,game.TEAL)
	var touch_layout=touch_animation_lab_layout(safe_rect_in_hud()) if game.is_touch else {}
	var preview_shift=touch_layout.get("shift",0.0)
	var panel_bottom=400-preview_shift
	game.animation_lab.preview_offset=preview_shift
	panel(Rect2(35,115,430,panel_bottom-115));panel(Rect2(495,115,430,panel_bottom-115))
	text(Vector2(60,146),"原版 · 姿势切帧",17)
	text(Vector2(520,146),"新版 · 二维网格 / 连续补间",17,game.GOLD)
	for x in [55,515]:canvas.draw_line(Vector2(x,375-preview_shift),Vector2(x+385,375-preview_shift),Color("638680"),2)
	var control_height=44 if game.is_touch else 36
	var control_y=touch_layout.control_y if game.is_touch else 451
	centered(control_y-24,game.animation_lab.title(),17,game.GOLD)
	var control_xs=[55.0,180.0,320.0,470.0,765.0]
	if game.is_touch:control_xs=touch_animation_lab_xs(safe_rect_in_hud())
	button(Rect2(control_xs[0],control_y,110,control_height),"暂停" if game.animation_lab.playing else "播放","lab_pause")
	button(Rect2(control_xs[1],control_y,125,control_height),"速度 ×"+str(game.animation_lab.speed),"lab_speed")
	button(Rect2(control_xs[2],control_y,110,control_height),"重播","lab_restart")
	button(Rect2(control_xs[3],control_y,235,control_height),"游戏：原画优化" if game.use_skeletal else "游戏：旧版图集","lab_switch")
	button(Rect2(control_xs[4],control_y,130,control_height),"返回","lab_back")
	centered(104 if game.is_touch else 518,"头颈完整 · 身体补间 · 挥剑有效时间与伤害同步",12,game.TEAL)

func controls_screen():
	canvas.draw_rect(Rect2(0,0,960,540),Color("111f2c"));centered(54,"手柄键位",28,game.GOLD)
	centered(85,"左摇杆移动 · 下方显示当前键位，可点选修改",14,game.TEAL)
	var labels=["跳跃","近战 / 长按蓄力","远程攻击","翻滚","冲刺","羊灵觉醒","召唤牛大侠","吃药 / 月露"]
	var columns=[80.0,500.0,175.0]
	if game.is_touch:columns=touch_controls_columns(safe_rect_in_hud())
	for i in game.gamepad.ACTIONS.size():
		var action_name=game.gamepad.ACTIONS[i];var x=columns[i%2];var y=111+(i/2)*58
		text(Vector2(x,y+25),labels[i],16)
		var waiting=game.gamepad.rebinding==action_name
		button(Rect2(x+190,y,columns[2],44 if game.is_touch else 36),"等待按键…" if waiting else game.gamepad.binding_label(action_name),"bind_"+action_name,waiting)
	var action_height=44 if game.is_touch else 38
	var action_y=touch_menu_row_y(safe_rect_in_hud(),455,action_height) if game.is_touch else 455
	var help_ys=touch_controls_help_ys(action_y) if game.is_touch else Vector2(380,410)
	centered(help_ys.x,"按下手柄新键 · Esc / Start 取消" if not game.gamepad.rebinding.is_empty() else "点选后按新键 · 长按近战蓄力",13,game.GOLD if not game.gamepad.rebinding.is_empty() else game.WHITE)
	centered(help_ys.y,"↓→ 斩 踏月剑气   ↓← 斩 回风斩   →↓→ 斩 升龙斩",12,game.GOLD)
	var action_xs=[75.0,365.0,650.0]
	if game.is_touch:action_xs=touch_controls_row_xs(safe_rect_in_hud())
	button(Rect2(action_xs[0],action_y,260,action_height),"按键图标："+{"auto":"自动","xbox":"Xbox","ps":"PlayStation","switch":"Switch"}.get(game.gamepad.glyphs,"自动"),"pad_glyphs")
	button(Rect2(action_xs[1],action_y,220,action_height),"恢复推荐键位","pad_reset")
	button(Rect2(action_xs[2],action_y,235,action_height),"返回","controls_back",true)

func moon_cinematic():
	if not is_instance_valid(game.boss):return
	var age=game.boss.recall_age
	var opacity=smoothstep(.65,1.3,age)*(1-smoothstep(5.8,6.4,age))
	canvas.draw_rect(Rect2(0,0,960,540),Color(.025,.02,.055,.22*opacity))
	canvas.draw_rect(Rect2(0,0,960,42*opacity),Color(0,0,0,.95))
	canvas.draw_rect(Rect2(0,540-42*opacity,960,42*opacity),Color(0,0,0,.95))
	if age>1 and age<4.8:centered(513,"此身……暂归月下。",17,Color(game.WHITE,opacity))
