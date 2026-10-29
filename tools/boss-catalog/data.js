window.BOSS_CATALOG = [
  {
    id: "lantern", name: "守灯兽", kind: "Boss · 1", role: "山门守卫", hp: 1500,
    phases: "守灯 → 灯火暴走", image: "assets/art/v2/bosses.png", sprite: "lantern",
    stats: [["最大生命", "1,500"], ["体型高度", "90 px"], ["碰撞半径", "34 px"]],
    description: "守着山门灯火的兽灵，擅长近身扑击与地面冲击。",
    summon: "无独立召唤单位。",
    moves: [
      ["pounce", "扑击", 18, 0.7, 0.8, "跃起扑向目标，落地造成冲击。"],
      ["sweep", "横扫", 16, 0.6, 0.8, "近身横向扫击。"],
      ["ground_wave", "地面冲击", 20, 0.9, 0.8, "向两侧扩散的地面波。"],
      ["pursuit", "追击", "—", "—", "—", "追赶玩家并寻找近身出手机会。"]
    ],
    voices: ["intro", "pounce", "sweep", "ground_wave", "pursuit", "phase_2", "low", "death"]
  },
  {
    id: "duelist", name: "渡影刀客", kind: "Boss · 2", role: "影刃刺客", hp: 2600,
    phases: "试刃 → 影刃加速", image: "assets/art/v2/bosses.png", sprite: "duelist",
    stats: [["最大生命", "2,600"], ["体型高度", "94 px"], ["碰撞半径", "34 px"], ["二阶段", "生命低于 50%"]],
    description: "快速突进、远程飞刃与影步换位交替进攻。",
    summon: "无独立召唤单位。",
    moves: [
      ["flash", "快闪刀", 24, 0.65, 0.8, "直线闪身斩。"],
      ["triple", "三段追身斩", "12 × 3", 0.7, 0.8, "连续三次追身斩。"],
      ["low_sweep", "低位扫堂刀", 22, 0.65, 0.8, "低位横扫。"],
      ["leap", "跃起劈落", 30, 0.85, 0.8, "跳至目标位置并劈落。"],
      ["fan", "扇形刀气", 18, 0.7, 0.8, "向扇形区域发出五道刀气。"],
      ["boomerang", "回旋飞刃", 20, 0.65, 0.8, "投出并返回的飞刃。"],
      ["shadow", "影步夹击", 28, 0.9, 0.8, "闪至目标附近并从两侧夹击。"]
    ],
    voices: ["intro", "flash", "triple", "low_sweep", "leap", "fan", "boomerang", "shadow", "phase_2", "low", "death"]
  },
  {
    id: "priest", name: "噬月祭主", kind: "Boss · 3", role: "月蚀术士", hp: 3600,
    phases: "迎月 → 月蚀初临 → 噬月终仪", image: "assets/art/v2/bosses.png", sprite: "priest",
    stats: [["最大生命", "3,600"], ["体型高度", "106 px"], ["二阶段", "生命低于 65%"], ["三阶段", "生命低于 30%"]],
    description: "结合冲阵、追踪弹、落雷与大范围符阵的远程术士。",
    summon: "不召唤独立单位；使用幽火弹、追魂弹、落雷与悬刃等术式。",
    moves: [
      ["horn", "羊角冲阵", 28, 0.75, 0.8, "沿直线冲撞。"],
      ["four_slash", "幽刃四连", "12 × 3 + 24", 0.8, 0.8, "连续四段近身斩击。"],
      ["ground_wave", "地裂波", 26, 0.85, 0.8, "沿地面扩散的裂隙波。"],
      ["lightning", "三连落雷符", "24 × 3", 0.9, 0.8, "连续三次追踪落雷。"],
      ["ring", "环形幽火", 20, 0.9, 0.8, "向周围发射幽火弹，留出一处闪避缺口。"],
      ["homing", "追魂弹", 22, 0.8, 0.8, "发射追踪幽火弹。"],
      ["beam", "横贯灵束", 32, 1.2, 1.2, "发射横向灵束。"],
      ["rain", "悬刃雨", 24, 1.2, 1.2, "落下悬刃，并留下安全区域。"],
      ["rift", "裂隙换位斩", 30, 0.9, 0.8, "闪至目标附近并斩击。"],
      ["ritual", "噬月大阵", 36, 1.4, 1.2, "发动大范围月蚀阵，中心区域安全。"]
    ],
    voices: ["intro", "horn", "four_slash", "ground_wave", "lightning", "ring", "homing", "beam", "rain", "rift", "ritual", "phase_2", "phase_3", "low", "death"]
  },
  {
    id: "knight", name: "断誓枪骑", kind: "Boss · 4", role: "骑枪守关者", hp: 2400,
    phases: "马战 → 步战", image: "assets/art/knight_frames/mounted/00.png",
    stats: [["马战生命", "2,400"], ["步战生命", "2,400"], ["攻击倍率", "0.9×"], ["体型高度", "148 / 106 px"]],
    description: "先以战马和长枪压迫，再下马展开步战；会针对牛大侠封锁葫芦。步战生命独立为 2400。",
    summon: "召来亡灵军团（战怒蓄满时必定发动；两格战怒有概率发动）。下马尘气可封住召唤葫芦 10 秒；步战时长枪有概率钉住牛大侠。",
    moves: [
      ["charge", "骑枪掠袭", 24, 0.65, 0.9, "马战直线冲锋，枪尖扫过行进路径。"], ["double_charge", "往返冲杀", 24, 0.75, "—", "冲锋后折返，再次掠袭。"],
      ["halt_thrust", "急停突刺", 24, 0.6, "—", "冲锋急停、短暂架势后向前刺击。"], ["trample", "冲阵踏蹄", "16 + 22", 0.55, "—", "冲锋途中撞击，停下后追加踏击。"],
      ["rein", "勒马折返", 22, 0.75, "—", "勒马转向，接续一次枪骑冲锋。"], ["rear", "前蹄重踏", "22（强化时追加 16）", 0.65, "—", "前蹄踏击；强化时波及身后。"],
      ["kick", "后蹄蹬踢", 18, 0.5, "—", "向身后踢击。"], ["butt", "枪柄压击", 16, 0.45, "—", "近身以枪柄压击。"],
      ["thrust", "测距点刺", 20, 0.45, 0.6, "短距离进身点刺。"], ["butt_spin", "枪尾回敲", 16, 0.5, 0.7, "脚战近身回敲。"],
      ["guard", "绞枪架势", "格挡后反击", 0.7, 0.55, "架枪防守，受到攻击后接绞枪反刺。"], ["counter", "绞枪反刺", 24, 0.45, 0.6, "格挡触发的快速反刺。"],
      ["advance", "三步逼阵", "16 × 3（强化时 4 段）", 0.6, 0.95, "连续踏步推进攻击。"], ["uppercut", "回缰挑枪", 22, 0.7, 1.0, "向前挑枪，可攻击空中目标。"],
      ["lunge", "贯甲进刺", 26, 0.72, 0.7, "快速进身穿刺。"], ["kick_thrust", "蹬踢接刺", "10 + 20", 0.5, 0.85, "先蹬踢，再接枪刺。"],
      ["spin_rush", "旋枪破阵", 26, 0.78, 0.85, "旋转长枪向前破阵。"], ["spear_return", "回锋掷矛", 20, 0.6, 0.55, "掷枪，枪飞出后折返。"],
      ["triple_dash", "三折追刺", "18 × 3（强化时 5 段）", 0.72, 1.0, "连续折线追身突刺。"], ["spear_slam", "踏进重挑", 28, 0.84, 0.85, "踏进后重挑长枪。"],
      ["bow", "定弦直射", "8 × 4（强化时 6 箭）", 0.7, 0.8, "瞄准后连续发射直线箭矢。"], ["bow_double", "退步双矢", "8 × 5（强化时 7 箭）", 0.7, 0.8, "后撤并连续射箭。"],
      ["bow_volley", "追猎三矢", "8 × 9（3 轮散射）", 0.65, 0.8, "连续三轮散射箭矢。"], ["wave", "三叠枪气", "24 × 3（强化时 5 段）", 0.42, 1.0, "发出贴地枪气；第三枪可能延迟。"],
      ["spear_chain", "刺进连挑", "20 × 2.46（分段倍率）", 0.62, 0.65, "刺进、推进、挑枪三段连招。"], ["dragon_sweep", "蛟龙扫阵", "20 × 1.85（分段倍率）", 0.7, 0.65, "低位扫阵并回枪。"],
      ["dragon_rise", "伏龙旋挑", "23 × 2.1（分段倍率）", 0.82, 0.8, "旋枪上挑攻击空中。"], ["dragon_break", "龙王破阵", "21 × 2.1（含全场枪气）", 0.9, 0.95, "长枪连段汇成全场低位枪气。"],
      ["soul_legion", "幽军降阵", "召唤亡灵士兵", 0.9, 0.35, "战怒满格时必定召来亡灵军团；两格时有概率发动。"], ["ancient_spear", "上古镇魂枪", "压制 10 秒", 1.1, 0.5, "锁定正在助战的牛大侠，将其钉在原地。"]
    ],
    voices: ["intro", "foot", "dismount", "spear_chain", "dragon_sweep", "dragon_rise", "dragon_break", "lunge", "counter", "guard", "stagger", "soul_legion", "soul_eagle_burst", "ancient_spear", "wave", "spin_rush", "spear_return", "triple_dash", "bow", "bow_double", "bow_volley", "spear_slam", "kick_thrust", "seal", "low", "death"],
    imageOptions: ["assets/art/knight_frames/mounted/00.png", "assets/art/knight_frames/foot/00.png", "assets/art/knight_frames/soul/00.png"]
  },
  {
    id: "lion_elder", name: "衔灯狮叟", kind: "Boss · 5", role: "狮舞武师", hp: 4600,
    phases: "狮先逗人 → 人来逗狮", image: "assets/art/lion_elder_frames/lion/00.png",
    stats: [["最大生命", "4,600"], ["本体显露", "生命低于 55%"], ["谢幕招式", "生命低于 25%"], ["体型高度", "120 / 86 px"]],
    description: "第一阶段由狮头狮身进攻，半血后露出狮叟本体；动作按节拍落点，招式间会休整。",
    summon: "不召唤敌方单位。牛大侠入场时狮叟会出声回应。",
    moves: [
      ["pounce", "探灯扑", 20, 0.78, 0.95, "狮头跃扑。"], ["wash_foot", "洗脚狮", 16, 0.86, 0.85, "贴地洗脚扫击。"],
      ["lion_slam", "举狮扣门", 28, 0.98, 1.1, "举起狮头重扣。"], ["lion_roll", "抱狮滚", 22, 0.86, 1.05, "抱狮翻滚向前。"],
      ["back_kick", "偷尾脚", 18, 0.82, 0.9, "向身后踢击。"], ["high_sweep", "狮口让路", 23, 0.92, 0.95, "高位横扫。"],
      ["lion_sleep", "狮睡惊醒", 21, 1.38, 1.15, "佯装沉睡后突然进攻。"], ["lion_steps", "三步逞威", "12 + 14 + 20", 0.75, 1.15, "连续三步打击。"],
      ["cup_elbow", "杯底藏肘", 18, 0.82, 0.75, "狮叟本体肘击。"], ["lean_kick", "铁板借腰", 22, 0.94, 1.05, "借腰发出踢击。"],
      ["sit_kick", "跌坐弹踵", 20, 1.04, 1.1, "跌坐后弹踵反击。"], ["ground_roll", "醉卧翻身", "14 + 20", 1.06, 1.2, "翻身后追加横扫。"],
      ["handstand", "倒挂金钟", 25, 1.25, 1.2, "倒立踢击，可被破势打断。"], ["turn_kick", "回身请客", 24, 0.98, 1.1, "转身回踢。"],
      ["toss_palm", "托壶穿掌", 20, 1.0, 0.9, "托壶后出掌。"], ["shuffle", "讨座挪凳", 21, 0.92, 1.0, "挪步进身攻击。"],
      ["double_palm", "拍灰双拍", "12 + 22", 0.82, 0.95, "连续双掌。"], ["twist", "失步拧花", "18 + 18", 1.06, 1.2, "失步后接拧身攻击。"],
      ["lion_finale", "狮醒敬客", "16 + 20", 1.0, 1.3, "狮舞与本体连携。"], ["drunk_finale", "醉里谢幕", "12 + 14 + 22", 1.1, 1.45, "三段收尾连招。"]
    ],
    voices: ["intro", "ally_enter", "phase_2", "pounce", "wash_foot", "lion_slam", "lion_roll", "back_kick", "high_sweep", "lion_sleep", "lion_steps", "cup_elbow", "lean_kick", "sit_kick", "ground_roll", "handstand", "turn_kick", "toss_palm", "shuffle", "double_palm", "twist", "lion_finale", "drunk_finale", "low", "defeat"],
    imageOptions: ["assets/art/lion_elder_frames/lion/00.png", "assets/art/lion_elder_frames/backfall/00.png", "assets/art/lion_elder_frames/sweep/00.png"]
  },
  {
    id: "bull", name: "牛大侠", kind: "召唤伙伴", role: "牛魔灵体", hp: 50,
    phases: "召唤入场 → 助战 → 离场冷却", image: "assets/art/v3/bull.png", sprite: "bull",
    description: "默认以四足牛形态从葫芦中现身，先载着羊小侠冲锋并回复生命，再自行寻找敌人攻击。",
    summon: "通关月下山门后解锁召唤葫芦。召唤耗时 1.2 秒；基础助战 30 秒；离场后冷却 25 秒。升级可延长助战时间。",
    stats: [["生命", "50"], ["普通冲撞", "22"], ["蓄力闪现冲撞", "28"], ["载行回复", "每秒 3 点，持续 5 秒"], ["基础助战", "30 秒"], ["离场冷却", "25 秒"], ["闪现冷却", "5 秒"]],
    moves: [
      ["carry", "载着羊小侠", "—", "—", "—", "召唤后先载行，帮助移动并回复生命。"],
      ["rush", "牛魔冲撞", "22", "—", "—", "短暂蓄力后直线冲撞；冲锋路径上的敌人受击。"],
      ["charged", "蓄力闪现冲撞", "28", "—", "—", "锁定目标后闪现到其身后，再发动强化冲撞。"],
      ["lifesteal", "命中回复", "按升级配置", "—", "—", "攻击命中后回复牛大侠生命。"]
    ],
    voices: ["bull_moo"],
    imageOptions: ["assets/art/v3/bull.png", "assets/art/v3/niu_human.png", "assets/art/v3/rider.png", "assets/art/v2/demon_parts.png"]
  }
];
