extends RefCounted
# Authored catalogue: data/voice/boss_dialogue.json.
const BOSSES={
 "lantern": {
  "title": "守灯兽",
  "voice": "Algenib",
  "lines": {
   "intro": "灯还亮着，谁也不准过去。",
   "intro_b": "脚步放轻，莫惊了这一山的灯。",
   "phase_2": "灯芯未灭，我便不退！",
   "phase_2_b": "这身皮毛烧尽，也要守住山门！",
   "low": "我守的，不只是一盏灯。",
   "low_b": "别碰它！这火，还不能熄。",
   "death": "灯下的路，交给你了。",
   "death_b": "往前走吧，别让灯灭了。",
   "pounce": "越过这道门，先过我这一扑！",
   "pounce_b": "小侠客，接住了！",
   "sweep": "灯影之外，也逃不过我。",
   "sweep_b": "绕到背后，就当我看不见？",
   "ground_wave": "这一山的石头，都认得我的脚步。",
   "ground_wave_b": "站得稳，再谈过山门！",
   "pursuit": "跑慢些，山路可不认人。",
   "pursuit_b": "灯照得见你，我也追得上你。"
  },
  "groups": {
   "intro": [
    "intro",
    "intro_b"
   ],
   "phase_2": [
    "phase_2",
    "phase_2_b"
   ],
   "low": [
    "low",
    "low_b"
   ],
   "death": [
    "death",
    "death_b"
   ],
   "pounce": [
    "pounce",
    "pounce_b",
    "pursuit",
    "pursuit_b"
   ],
   "sweep": [
    "sweep",
    "sweep_b"
   ],
   "ground_wave": [
    "ground_wave",
    "ground_wave_b"
   ],
   "pursuit": [
    "pursuit",
    "pursuit_b"
   ]
  },
  "performance": "中文游戏BOSS角色配音。山门巨兽，粗粝胸腔共鸣，压着怒火、警告入侵者，威严凶猛。 禁止平静播报、朗读腔；只念输入的台词，不念任何指导，不加词。保持清晰，留出短停顿，避免全句持续尖叫。",
  "efforts": {
   "effort_ha": "哈！",
   "effort_ah": "啊！"
  }
 },
 "duelist": {
  "title": "渡影刀客",
  "voice": "Schedar",
  "lines": {
   "intro": "过渡口可以，留下你的破绽。",
   "intro_b": "月照水面，刀照人心。请。",
   "phase_2": "试刀到此。接下来，分个高下。",
   "phase_2_b": "你跟得上影子，未必跟得上刀。",
   "low": "这一身伤，倒让我想起年轻时候。",
   "low_b": "好刀法。可我还没有认输。",
   "death": "这一渡，你过得。",
   "death_b": "收好你的剑。往后，还有更险的路。",
   "flash": "影未落，刀先到。",
   "flash_b": "眨眼，可就晚了。",
   "triple": "一刀试身，二刀追影，三刀断路。",
   "triple_b": "别急，后面还有。",
   "low_sweep": "高处有月，低处有刀。",
   "low_sweep_b": "脚下的破绽，比眼前更大。",
   "leap": "抬头！",
   "leap_b": "这一刀，自月下来。",
   "fan": "退路，我替你量过了。",
   "fan_b": "水面千重，刀光一线。",
   "boomerang": "刀还未归，莫急着出手。",
   "boomerang_b": "去的是刃，回来的也是。",
   "shadow": "你看见的，是哪一个我？",
   "shadow_b": "影落两处，刀只认你。"
  },
  "groups": {
   "intro": [
    "intro",
    "intro_b"
   ],
   "phase_2": [
    "phase_2",
    "phase_2_b"
   ],
   "low": [
    "low",
    "low_b"
   ],
   "death": [
    "death",
    "death_b"
   ],
   "flash": [
    "flash",
    "flash_b"
   ],
   "triple": [
    "triple",
    "triple_b"
   ],
   "low_sweep": [
    "low_sweep",
    "low_sweep_b"
   ],
   "leap": [
    "leap",
    "leap_b"
   ],
   "fan": [
    "fan",
    "fan_b"
   ],
   "boomerang": [
    "boomerang",
    "boomerang_b"
   ],
   "shadow": [
    "shadow",
    "shadow_b"
   ]
  },
  "performance": "中文游戏BOSS角色配音。冷酷的武林刀客，咬字利落带杀意，挑衅时轻蔑，进攻时爆发。 禁止平静播报、朗读腔；只念输入的台词，不念任何指导，不加词。保持清晰，留出短停顿，避免全句持续尖叫。",
  "efforts": {
   "effort_ha": "哈！",
   "effort_ah": "啊！"
  }
 },
 "priest": {
  "title": "噬月祭主",
  "voice": "Charon",
  "lines": {
   "intro": "月光照不到的地方，才是我的祭坛。",
   "intro_b": "小小羊灵，也敢踏入噬月之仪？",
   "phase_2": "第一道月痕，开！",
   "phase_2_b": "借来的月光，终要归还。",
   "phase_3": "长夜将尽？不，是月亮将尽！",
   "phase_3_b": "众影听令，以此身，吞尽月华！",
   "low": "仪式未成，我怎能倒下！",
   "low_b": "月蚀尚在，命火不休。",
   "death": "原来，月光并不属于我。",
   "death_b": "长夜之后，竟还有你们的路。",
   "horn": "踏碎这束月光！",
   "four_slash": "四方幽刃，合！",
   "ground_wave": "地脉苏醒，听我号令！",
   "lightning": "雷落三重，莫问归处。",
   "lightning_b": "天上，也没有你的退路。",
   "ring": "幽火所至，皆为祭土。",
   "homing": "你的魂息，已经记下了。",
   "beam": "抬首，见证这道噬月之光。",
   "beam_b": "月华成束，照破你的躲藏。",
   "rain": "听，天上有刀。",
   "rain_b": "千刃悬月，落！",
   "rift": "裂隙之中，影随我行。",
   "ritual": "众影归坛，噬月！",
   "ritual_b": "身在阵中，何处不是长夜？"
  },
  "groups": {
   "intro": [
    "intro",
    "intro_b"
   ],
   "phase_2": [
    "phase_2",
    "phase_2_b"
   ],
   "phase_3": [
    "phase_3",
    "phase_3_b"
   ],
   "low": [
    "low",
    "low_b"
   ],
   "death": [
    "death",
    "death_b"
   ],
   "horn": [
    "horn"
   ],
   "four_slash": [
    "four_slash"
   ],
   "ground_wave": [
    "ground_wave"
   ],
   "lightning": [
    "lightning",
    "lightning_b"
   ],
   "ring": [
    "ring"
   ],
   "homing": [
    "homing"
   ],
   "beam": [
    "beam",
    "beam_b"
   ],
   "rain": [
    "rain",
    "rain_b"
   ],
   "rift": [
    "rift"
   ],
   "ritual": [
    "ritual",
    "ritual_b"
   ]
  },
  "performance": "中文游戏BOSS角色配音。阴森的祭司，低沉沙哑、笃定而危险，像宣判，不要轻松或温柔。 禁止平静播报、朗读腔；只念输入的台词，不念任何指导，不加词。保持清晰，留出短停顿，避免全句持续尖叫。",
  "efforts": {
   "effort_ha": "哈！",
   "effort_ah": "啊！"
  }
 },
 "knight": {
  "title": "断誓枪骑",
  "voice": "Orus",
  "lines": {
   "intro": "止步。此地，由我的枪守着。",
   "foot": "不必试马了。你我，凭本事决胜。",
   "dismount": "马可退，人不退。来，接我这一枪！",
   "spin_rush": "枪锋所向，破阵！",
   "spear_return": "躲得过来枪，躲得过回锋吗？",
   "triple_dash": "一枪未尽，再接两枪！",
   "bow_volley": "你逃跑的路，我看得清。",
   "wave": "看清楚，第三枪！",
   "pursuit": "只会逃，可赢不了我。",
   "seal": "葫芦救不了你。",
   "low": "铠甲可碎，誓言不折！",
   "death": "好身手。这条路，归你了。",
   "intro_b": "这道山门，不曾向逃兵敞开。",
   "foot_b": "下了马，才是我的真本事。",
   "dismount_b": "坐骑歇了，我的枪还没歇！",
   "spear_chain": "枪有三节，看清每一节。",
   "spear_chain_b": "先刺，再进，最后这一挑！",
   "dragon_sweep": "枪走下盘，你站稳了吗？",
   "dragon_sweep_b": "躲过低锋，再看回枪！",
   "dragon_rise": "旋枪聚势，起！",
   "dragon_rise_b": "天上，也在枪锋之内！",
   "dragon_break": "乱枪归一，破阵开山！",
   "dragon_break_b": "这一枪，敬我未归的同袍！",
   "lunge": "收枪，是为下一刺。",
   "lunge_b": "一线枪锋，穿甲而过！",
   "counter": "你的破绽，我看见了。",
   "guard": "来，试试谁先露出破绽。",
   "stagger": "好！你破得开我的枪架。",
   "soul_legion": "旧日的同袍，再随我冲阵！",
   "soul_legion_b": "战旗未倒，众将随我！",
   "wave_b": "抬枪之时，便是你起跳之时。",
   "spin_rush_b": "人随枪进，休想拉开！",
   "spear_return_b": "枪去有归，莫急着追。",
   "bow_volley_b": "风过弓弦，箭不落空。",
   "low_b": "还未倒下，就还守得住！",
   "death_b": "枪已尽。你，走吧。",
   "intro_c": "我守这道关，不问来者姓名。",
   "foot_c": "马蹄已歇，枪锋未歇。",
   "dismount_c": "落地再战，休想趁隙！",
   "soul_eagle_burst": "紫鹰，替我巡视这片战场！",
   "soul_eagle_burst_b": "鹰鸣之下，无处藏身！",
   "ancient_spear": "古枪听令，镇住此身！",
   "ancient_spear_b": "这一枪，钉住你的援手！",
   "soul_legion_c": "故人披甲，随我再冲一回！",
   "triple_dash_b": "一步追身，再一步断路！",
   "bow": "弦已满，莫回头！",
   "bow_b": "箭识归途，你往哪里去？",
   "bow_double": "退这半步，是为再进！",
   "guard_b": "枪架不倒，任你来试。",
   "counter_b": "这一处空门，我收下了。",
   "stagger_b": "好力道！再来！",
   "low_c": "血可流，守关的誓不可丢！",
   "death_c": "同袍，今日便守到这里了。",
   "spear_slam": "枪落如山！",
   "kick_thrust": "近身了？那就接稳！"
  },
  "groups": {
   "intro": [
    "intro",
    "intro_b",
    "intro_c"
   ],
   "foot": [
    "foot",
    "foot_b",
    "foot_c"
   ],
   "dismount": [
    "dismount",
    "dismount_b",
    "dismount_c"
   ],
   "spear_chain": [
    "spear_chain",
    "spear_chain_b"
   ],
   "dragon_sweep": [
    "dragon_sweep",
    "dragon_sweep_b"
   ],
   "dragon_rise": [
    "dragon_rise",
    "dragon_rise_b"
   ],
   "dragon_break": [
    "dragon_break",
    "dragon_break_b"
   ],
   "lunge": [
    "lunge",
    "lunge_b"
   ],
   "soul_legion": [
    "soul_legion",
    "soul_legion_b",
    "soul_legion_c"
   ],
   "wave": [
    "wave",
    "wave_b"
   ],
   "spin_rush": [
    "spin_rush",
    "spin_rush_b"
   ],
   "spear_return": [
    "spear_return",
    "spear_return_b"
   ],
   "bow_volley": [
    "bow_volley",
    "bow_volley_b"
   ],
   "low": [
    "low",
    "low_b",
    "low_c"
   ],
   "death": [
    "death",
    "death_b",
    "death_c"
   ],
   "soul_eagle_burst": [
    "soul_eagle_burst",
    "soul_eagle_burst_b",
    "seal"
   ],
   "ancient_spear": [
    "ancient_spear",
    "ancient_spear_b"
   ],
   "triple_dash": [
    "triple_dash",
    "triple_dash_b",
    "pursuit"
   ],
   "bow": [
    "bow",
    "bow_b"
   ],
   "bow_double": [
    "bow_double"
   ],
   "guard": [
    "guard",
    "guard_b"
   ],
   "counter": [
    "counter",
    "counter_b"
   ],
   "stagger": [
    "stagger",
    "stagger_b"
   ],
   "spear_slam": [
    "spear_slam"
   ],
   "kick_thrust": [
    "kick_thrust"
   ]
  },
  "performance": "中文游戏BOSS角色配音。披重甲的战场统帅，低沉有力、带压迫感与怒意，胸腔共鸣，重读威胁词，进攻台词果断短促。 禁止平静播报、朗读腔；只念输入的台词，不念任何指导，不加词。保持清晰，留出短停顿，避免全句持续尖叫。",
  "efforts": {
   "effort_ha": "哈！",
   "effort_ah": "啊！",
   "effort_aha": "啊哈！",
   "effort_he": "喝！",
   "effort_hei": "嘿！",
   "effort_heng": "哼！",
   "effort_ya": "呀！",
   "effort_zhe": "着！",
   "effort_kanqiang": "看枪！",
   "effort_po": "破！",
   "effort_qi": "起！"
  }
 }
}
