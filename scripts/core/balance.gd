extends RefCounted
const PATH="user://balance_v1.json"
# label, default, minimum, maximum, step; probability fields are displayed as percentages.
const SCHEMA={
 "proc_threshold":["触发血量上限（低于）",80.0,1,100,1],
 "critical_threshold":["濒危血量上限（低于）",30.0,1,100,1],
 "proc_chance":["低血量变身概率 %",5.0,0,100,1],
 "critical_chance":["濒危变身概率 %",30.0,0,100,1],
 "ally_hp":["牛大侠 / 牛魔最大生命",50.0,1,500,1],
 "extension":["变身延长时间（秒）",30.0,0,120,1],
 "carry_duration":["骑乘保护时间（秒）",7.0,1,20,.5],
 "heal_duration":["治疗持续时间（秒）",5.0,1,20,1],
 "heal_rate":["每秒恢复主角生命",3.0,0,20,1],
 "lifesteal":["牛魔每次命中自愈",1.0,0,10,1],
 "demon_damage":["牛魔冲撞伤害",22.0,1,100,1],
 "charged_damage":["蓄力闪现冲撞伤害",28.0,1,150,1],
 "demon_interval":["普通攻击间隔（秒）",1.35,.5,5,.05],
 "blink_cooldown":["闪现冷却（秒）",5.0,2,20,.5],
 "lock_time":["闪现锁定预兆（秒）",.75,.45,3,.05],
 "charge_time":["蓄爆锁定预兆（秒）",1.2,.8,4,.1],
 "demon_range":["冲撞行程（像素）",180.0,60,280,5],
 "max_targets":["每次冲撞命中目标上限",3.0,1,5,1],
 "demon_incoming":["牛魔受到伤害倍率",.65,.1,2,.05],
 "normal_incoming":["牛大侠受到伤害倍率",1.0,.1,2,.05],
 "ally_iframes":["助战受击无敌时间（秒）",.65,.2,2,.05],
 "card_damage":["飞牌伤害",12.0,1,60,1],
 "fan_damage":["散牌单张伤害",8.0,1,40,1],
 "return_damage":["回环牌单程伤害",10.0,1,40,1],
 "rune_damage":["牌阵伤害",10.0,1,40,1],
 "assist_duration":["基础助战时间（秒）",30.0,5,120,1],
 "summon_cooldown":["离场后召唤冷却（秒）",25.0,0,300,5],
 "rush_speed":["冲撞速度（像素 / 秒）",440.0,200,650,10],
 "rush_windup":["冲撞预兆（秒）",.4,.25,1.2,.05],
 "knight_rage_release":["满格战怒释放概率 %",75.0,0,100,1],
 "knight_rage_fraction":["骑士每格战怒所需失血比例",.04,.03,.08,.005],
 "knight_mount_hp":["断誓枪骑 · 马战生命",2400.0,100,20000,50],
 "knight_foot_hp":["断誓枪骑 · 步战生命",2400.0,100,20000,50],
 "knight_spear_chain_windup":["刺进连挑准备（秒）",0.62,.4,1.5,.02],
 "knight_spear_chain_damage":["刺进连挑基础伤害",20,5,40,1],
 "knight_dragon_sweep_windup":["蛟龙扫阵准备（秒）",0.7,.4,1.5,.02],
 "knight_dragon_sweep_damage":["蛟龙扫阵基础伤害",20,5,40,1],
 "knight_dragon_rise_windup":["伏龙旋挑准备（秒）",0.82,.4,1.5,.02],
 "knight_dragon_rise_damage":["伏龙旋挑基础伤害",23,5,40,1],
 "knight_dragon_break_windup":["龙王破阵准备（秒）",0.9,.4,1.5,.02],
 "knight_dragon_break_damage":["龙王破阵基础伤害",21,5,40,1],
 "knight_damage_scale":["断誓枪骑 · 攻击伤害倍率",.9,.5,1.5,.01],
 "knight_charge_windup":["骑枪掠袭准备（秒）",.65,.3,2,.05],
 "knight_turn_windup":["勒马折返准备（秒）",.75,.3,2,.05],
 "knight_rear_windup":["前蹄重踏准备（秒）",.65,.3,2,.05],
 "knight_kick_windup":["后蹄蹬踢准备（秒）",.5,.3,2,.05],
 "knight_butt_windup":["枪柄压击准备（秒）",.45,.25,2,.05],
 "knight_thrust_windup":["测距点刺准备（秒）",.45,.25,2,.05],
 "knight_bow_draw":["定弦直射拉弓（秒）",.7,.4,2,.05],
 "knight_recovery_scale":["骑士收招时长倍率",1.0,.5,2,.05],
 "knight_wave_gap":["三叠枪气 · 匀速间隔（秒）",1.1,.7,3,.05],
 "knight_wave_late":["三叠枪气 · 延迟第三枪间隔（秒）",2.05,1.65,4,.05],
 "knight_dust_seal":["下马尘气封葫芦（秒）",10.0,1,30,.5],
 "knight_hit_seal":["弓箭命中封葫芦（秒）",2.0,1,30,.5],
 "knight_advance_windup":["三步逼阵准备（秒）",.6,.4,1.5,.05],
 "knight_advance_damage":["三步逼阵每踏伤害",16.0,1,50,1],
 "knight_uppercut_windup":["回缰挑枪准备（秒）",.7,.45,1.8,.05],
 "knight_uppercut_damage":["回缰挑枪伤害",22.0,1,70,1],
 "knight_lunge_windup":["贯甲进刺准备（秒）",.72,.45,1.8,.05],
 "knight_lunge_damage":["贯甲进刺伤害",26.0,1,80,1],
 "knight_kick_thrust_windup":["蹬踢接刺准备（秒）",.5,.35,1.5,.05],
 "knight_kick_thrust_damage":["蹬踢伤害（接刺×2）",10.0,1,35,1],
 "knight_bow_double_windup":["退步双矢拉弓（秒）",.7,.45,.85,.05],
 "knight_spin_rush_windup":["旋枪破阵准备（秒）",0.78,.4,1.5,.05],
 "knight_spin_rush_damage":["旋枪破阵单段伤害",26.0,1,80,1],
 "knight_spear_return_windup":["回锋掷矛准备（秒）",0.6,.4,1.5,.05],
 "knight_spear_return_damage":["回锋掷矛单段伤害",20.0,1,80,1],
 "knight_triple_dash_windup":["三折追刺准备（秒）",0.72,.4,1.5,.05],
 "knight_triple_dash_damage":["三折追刺单段伤害",18.0,1,80,1],
 "knight_bow_volley_windup":["追猎三矢准备（秒）",0.65,.4,1.5,.05],
 "knight_spear_slam_windup":["踏进重挑准备（秒）",0.84,.4,1.5,.05],
 "knight_spear_slam_damage":["踏进重挑单段伤害",28.0,1,80,1],
 "knight_dash_speed":["贯甲突进速度",780.0,500,1100,10],
 "knight_spin_speed":["旋枪破阵速度",900.0,600,1200,10],
 "knight_triple_speed":["三折追刺速度",900.0,600,1200,10],
 "knight_throw_speed":["回锋掷矛速度",820.0,600,1100,10]
}
var values={}
func _init():reset();load_settings()
func reset():
 values.clear()
 for key in SCHEMA:values[key]=float(SCHEMA[key][1])
func get_value(key):return float(values.get(key,SCHEMA[key][1]))
func apply(data):
 for key in SCHEMA:
  var value=data.get(key,values[key])
  if (value is float or value is int) and is_finite(float(value)):
   values[key]=clampf(float(value),SCHEMA[key][2],SCHEMA[key][3])
 values.critical_threshold=minf(values.critical_threshold,values.proc_threshold)
 values.heal_duration=minf(values.heal_duration,values.carry_duration)
 # A full jump keeps the feet above the spear wave for about 0.92 s, so the late
 # third wave must stay at least 0.95 s later than the even rhythm.
 values.knight_wave_late=maxf(values.knight_wave_late,values.knight_wave_gap+.95)
func load_settings():
 if FileAccess.file_exists(PATH):
  var parsed=JSON.parse_string(FileAccess.get_file_as_string(PATH))
  if parsed is Dictionary:apply(parsed)
func save_settings():
 var file=FileAccess.open(PATH,FileAccess.WRITE)
 if file:file.store_string(JSON.stringify(values));return true
 return false
func probability(health):
 if health<get_value("critical_threshold"):return get_value("critical_chance")/100.0
 if health<get_value("proc_threshold"):return get_value("proc_chance")/100.0
 return 0.0
