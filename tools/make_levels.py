"""Compile authored, fixed stage layouts into inspectable Godot Resources. No runtime random map generation."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
def gd(v):
 if isinstance(v,str):return json.dumps(v,ensure_ascii=False)
 if isinstance(v,bool):return 'true' if v else 'false'
 if isinstance(v,(int,float)):return str(v)
 if isinstance(v,list):return '['+', '.join(gd(x) for x in v)+']'
 if isinstance(v,dict):return '{'+', '.join(gd(k)+': '+gd(x) for k,x in v.items())+'}'
 raise ValueError(v)
titles=['月下山门','雾林古渡','幽钟祭坛']
sections=[['山门石阶','断桥水径','机关庭院','守灯月庭'],['竹林伏道','摆渡残桥','石卫水闸','渡影决斗'],['幽钟墓道','悬灯裂谷','双印祭庭','终焉祭坛']]
rosters=[['imp','pouncer','bat','spirit'],['dart','shield','guardian','shaman'],['shaman','guardian','bat','shield']]
for idx in range(3):
 platforms=[];spawns=[];pickups=[];features=[]
 def slab(x,y,w,h=240,one=False):platforms.append(dict(x=x,y=y,w=w,h=h,one_way=one))
 for room in range(4):
  s=room*4000
  if room==0:
   # Ground-led ascent, a roofed passage and an optional rooftop supply route.
   for x,y,w in [(0,450,850),(850,390,420),(1270,330,420),(1690,390,380),(2070,450,1930)]:slab(s+x,y,w)
   slab(s+2380,325,600,35);slab(s+2320,370,110,14,True);slab(s+2880,240,230,14,True)
   slab(s+3160,370,200,14,True)
   pickups.append(dict(x=s+3000,y=218,kind='spirit',id=f'{idx}_roof'))
   pickups.append(dict(x=s+3060,y=218,kind='relic',id=f'moon_{idx+1}_roof'))
   if idx==1:features.append(dict(kind='gust',x=s+1750,y=170,w=1850,h=310,force=58.0))
   if idx==2:features.append(dict(kind='ritual',x=s+1880,y=450,radius=92.0,period=3.8,phase=.4,damage=10.0))
  elif room==1:
   # Broad water gap with an actual ferry, plus a fully traversable upper bridge.
   slab(s,450,900);slab(s+1420,450,680);slab(s+2580,450,1420)
   for x,y,w in [(820,370,200),(1100,300,200),(1380,370,210),(2040,360,220),(2340,300,220),(2630,365,220)]:slab(s+x,y,w,16,True)
   features += [dict(kind='ferry',x=s+930,y=425,w=190,travel=320,speed=.65),dict(kind='lift',x=s+2150,y=435,w=175,travel=140,speed=.8)]
   if idx==1:features.append(dict(kind='gust',x=s+1450,y=150,w=1750,h=335,force=-52.0))
   pickups.append(dict(x=s+2400,y=280,kind='heal',id=f'{idx}_bridge'))
  elif room==2:
   # Courtyard pressure seal opens a gate; rooftop bypass is optional.
   slab(s,450,4000);slab(s+740,365,180,85);slab(s+920,290,520,160)
   slab(s+1370,205,260,14,True);slab(s+1710,290,220,14,True)
   slab(s+2400,360,360,90);slab(s+3070,360,190,14,True)
   features += [dict(kind='plate',x=s+580,y=450,w=72,gate=s+2040),dict(kind='gate',x=s+2040,y=235,w=28,h=215),dict(kind='spikes',x=s+2900,y=450,w=115,period=3.6+idx*.3)]
   pickups.append(dict(x=s+1500,y=184,kind='spirit',id=f'{idx}_seal'))
   pickups.append(dict(x=s+1585,y=184,kind='relic',id=f'moon_{idx+1}_seal'))
   if idx==2:features += [dict(kind='plate',x=s+2800,y=450,w=72,gate=s+3420),dict(kind='gate',x=s+3420,y=235,w=28,h=215)]
   if idx==2:features += [dict(kind='ritual',x=s+1780,y=450,radius=96.0,period=4.1,phase=0.0,damage=10.0),dict(kind='ritual',x=s+2580,y=450,radius=105.0,period=4.1,phase=2.05,damage=10.0)]
  else:
   # Short antechamber and a wide, clear boss stage.
   slab(s,450,4000);slab(s+340,365,230,85);slab(s+850,370,230,14,True)
   pickups.append(dict(x=s+1100,y=426,kind='heal',id=f'{idx}_boss_supply'))
  positions=([560,1120,1550,1950,2240,2640,3200,3520] if room==0 else ([550,1570,1850,2740,3050,3440] if room==1 else ([360,810,1180,1810,2200,2500,3180,3550] if room==2 else [450,1000])))
  for j,x in enumerate(positions):
   kind=rosters[idx][(j+room)%4];top=450
   candidates=[p['y'] for p in platforms if not p['one_way'] and p['x']<=s+x<p['x']+p['w']]
   if candidates:top=min(candidates)
   if kind in ('bat','spirit'):top-=70
   spawns.append(dict(x=s+x,y=top,kind=kind,section=room,id=f'v4_{idx}_{room}_{j}'))
 if idx==0:pickups.append(dict(x=690,y=427,kind='bow',id='first_bow'))
 out='[gd_resource type="Resource" load_steps=2 format=3]\n[ext_resource type="Script" path="res://scripts/world/level_spec.gd" id="1"]\n[resource]\nscript = ExtResource("1")\n'
 out+=f'number = {idx+1}\ntitle = {gd(titles[idx])}\nlength = 16000.0\nsection_names = PackedStringArray({", ".join(gd(x) for x in sections[idx])})\n'
 out+=f'platforms = {gd(platforms)}\nspawns = {gd(spawns)}\npickups = {gd(pickups)}\nfeatures = {gd(features)}\ncheckpoints = PackedFloat32Array(100, 8100, 13700)\nboss_id = {gd(["lantern","duelist","priest"][idx])}\nboss_x = 14900.0\n'
 (ROOT/f'data/levels/level_{idx+1}.tres').write_text(out)
sets=[('lantern','守灯兽',1500,[('pounce','扑击',18,.7),('sweep','横扫',16,.6),('ground_wave','地面冲击',20,.9)]),('duelist','渡影刀客',2600,[('flash','快闪刀',24,.65),('triple','三段追身斩',12,.7),('low_sweep','低位扫堂刀',22,.65),('leap','跃起劈落',30,.85),('fan','扇形刀气',18,.7),('boomerang','回旋飞刃',20,.65),('shadow','影步夹击',28,.9)]),('priest','噬月祭主',3600,[('horn','羊角冲阵',28,.75),('four_slash','幽刃四连',12,.8),('ground_wave','地裂波',26,.85),('lightning','三连落雷符',24,.9),('ring','环形幽火',20,.9),('homing','追魂弹',22,.8),('beam','横贯灵束',32,1.2),('rain','悬刃雨',24,1.2),('rift','裂隙换位斩',30,.9),('ritual','噬月大阵',36,1.4)])]
for id,title,hp,moves in sets:
 a=[dict(id=i,title=t,damage=d,windup=w,recovery=.8 if w<1 else 1.2) for i,t,d,w in moves]
 (ROOT/f'data/bosses/{id}.tres').write_text('[gd_resource type="Resource" load_steps=2 format=3]\n[ext_resource type="Script" path="res://scripts/combat/move_set.gd" id="1"]\n[resource]\nscript = ExtResource("1")\n'+f'id = {gd(id)}\ntitle = {gd(title)}\nhealth = {float(hp)}\nmoves = {gd(a)}\n')
print('Authored 3 fixed levels, 4 distinct sections each; ferry, lift, pressure gate, timed spikes.')
