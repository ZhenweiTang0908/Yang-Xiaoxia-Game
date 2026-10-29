extends RefCounted
# Approved behavior: docs/lion-elder-design.md; values are exposed through F2.
const MOVES={
 "M01": {
  "id": "M01",
  "title": "探灯扑",
  "voice": "pounce",
  "beats": [
   [
    0.78,
    18,
    80,
    20,
    86,
    20
   ]
  ],
  "recovery": 0.95,
  "bank": "lion",
  "contacts": [
   9
  ],
  "travel": 150,
  "window": 0.24
 },
 "M02": {
  "id": "M02",
  "title": "洗脚狮",
  "voice": "wash_foot",
  "beats": [
   [
    0.86,
    8,
    80,
    0,
    25,
    16
   ]
  ],
  "recovery": 0.85,
  "bank": "lion",
  "contacts": [
   2
  ],
  "travel": 0,
  "window": 0.12
 },
 "M03": {
  "id": "M03",
  "title": "举狮扣门",
  "voice": "lion_slam",
  "beats": [
   [
    0.98,
    30,
    100,
    0,
    100,
    28
   ]
  ],
  "recovery": 1.1,
  "bank": "lion",
  "contacts": [
   10
  ],
  "travel": 0,
  "window": 0.12
 },
 "M04": {
  "id": "M04",
  "title": "抱狮滚",
  "voice": "lion_roll",
  "beats": [
   [
    0.86,
    -24,
    40,
    0,
    58,
    22
   ]
  ],
  "recovery": 1.05,
  "bank": "lion",
  "contacts": [
   9
  ],
  "travel": 190,
  "window": 0.36
 },
 "M05": {
  "id": "M05",
  "title": "偷尾脚",
  "voice": "back_kick",
  "beats": [
   [
    0.82,
    -65,
    -8,
    8,
    52,
    18
   ]
  ],
  "recovery": 0.9,
  "bank": "lion",
  "contacts": [
   2
  ],
  "travel": 0,
  "window": 0.12
 },
 "M06": {
  "id": "M06",
  "title": "狮口让路",
  "voice": "high_sweep",
  "beats": [
   [
    0.92,
    5,
    105,
    62,
    118,
    23
   ]
  ],
  "recovery": 0.95,
  "bank": "lion",
  "contacts": [
   6
  ],
  "travel": 0,
  "window": 0.12
 },
 "M07": {
  "id": "M07",
  "title": "狮睡惊醒",
  "voice": "lion_sleep",
  "beats": [
   [
    1.38,
    5,
    65,
    12,
    68,
    21
   ]
  ],
  "recovery": 1.15,
  "bank": "lion",
  "contacts": [
   9
  ],
  "travel": 0,
  "window": 0.12
 },
 "M08": {
  "id": "M08",
  "title": "三步逞威",
  "voice": "lion_steps",
  "beats": [
   [
    0.75,
    5,
    45,
    0,
    42,
    12
   ],
   [
    1.55,
    5,
    45,
    0,
    42,
    14
   ],
   [
    2.4,
    5,
    45,
    0,
    42,
    20
   ]
  ],
  "recovery": 1.15,
  "bank": "lion",
  "contacts": [
   3,
   4,
   6
  ],
  "travel": 114,
  "window": 0.12
 },
 "M09": {
  "id": "M09",
  "title": "杯底藏肘",
  "voice": "cup_elbow",
  "beats": [
   [
    0.82,
    5,
    65,
    18,
    64,
    18
   ]
  ],
  "recovery": 0.75,
  "bank": "backfall",
  "contacts": [
   0
  ],
  "travel": 0,
  "window": 0.12
 },
 "M10": {
  "id": "M10",
  "title": "铁板借腰",
  "voice": "lean_kick",
  "beats": [
   [
    0.94,
    5,
    85,
    0,
    32,
    22
   ]
  ],
  "recovery": 1.05,
  "bank": "backfall",
  "contacts": [
   4
  ],
  "travel": 0,
  "window": 0.12
 },
 "M11": {
  "id": "M11",
  "title": "跌坐弹踵",
  "voice": "sit_kick",
  "beats": [
   [
    1.04,
    0,
    70,
    0,
    45,
    20
   ]
  ],
  "recovery": 1.1,
  "bank": "backfall",
  "contacts": [
   5
  ],
  "travel": 0,
  "window": 0.12
 },
 "M12": {
  "id": "M12",
  "title": "醉卧翻身",
  "voice": "ground_roll",
  "beats": [
   [
    1.06,
    0,
    85,
    0,
    26,
    14
   ],
   [
    1.82,
    0,
    90,
    62,
    125,
    20
   ]
  ],
  "recovery": 1.2,
  "bank": "sweep",
  "contacts": [
   4,
   11
  ],
  "travel": 0,
  "window": 0.12
 },
 "M13": {
  "id": "M13",
  "title": "倒挂金钟",
  "voice": "handstand",
  "beats": [
   [
    1.25,
    0,
    100,
    70,
    150,
    25
   ]
  ],
  "recovery": 1.2,
  "bank": "sweep",
  "contacts": [
   11
  ],
  "travel": 0,
  "window": 0.12
 },
 "M14": {
  "id": "M14",
  "title": "回身请客",
  "voice": "turn_kick",
  "beats": [
   [
    0.98,
    0,
    85,
    18,
    72,
    24
   ]
  ],
  "recovery": 1.1,
  "bank": "backfall",
  "contacts": [
   4
  ],
  "travel": -60,
  "window": 0.12
 },
 "M15": {
  "id": "M15",
  "title": "托壶穿掌",
  "voice": "toss_palm",
  "beats": [
   [
    1.0,
    0,
    75,
    15,
    60,
    20
   ]
  ],
  "recovery": 0.9,
  "bank": "backfall",
  "contacts": [
   0
  ],
  "travel": 0,
  "window": 0.12
 },
 "M16": {
  "id": "M16",
  "title": "讨座挪凳",
  "voice": "shuffle",
  "beats": [
   [
    0.92,
    -10,
    40,
    14,
    58,
    21
   ]
  ],
  "recovery": 1.0,
  "bank": "backfall",
  "contacts": [
   1
  ],
  "travel": 100,
  "window": 0.18
 },
 "M17": {
  "id": "M17",
  "title": "拍灰双拍",
  "voice": "double_palm",
  "beats": [
   [
    0.82,
    0,
    60,
    22,
    68,
    12
   ],
   [
    1.56,
    0,
    85,
    12,
    60,
    22
   ]
  ],
  "recovery": 0.95,
  "bank": "backfall",
  "contacts": [
   0,
   1
  ],
  "travel": 0,
  "window": 0.12
 },
 "M18": {
  "id": "M18",
  "title": "失步拧花",
  "voice": "twist",
  "beats": [
   [
    1.06,
    0,
    95,
    35,
    95,
    18
   ],
   [
    1.85,
    -5,
    65,
    0,
    48,
    18
   ]
  ],
  "recovery": 1.2,
  "bank": "sweep",
  "contacts": [
   9,
   3
  ],
  "travel": 0,
  "window": 0.12
 },
 "M19": {
  "id": "M19",
  "title": "狮醒敬客",
  "voice": "lion_finale",
  "beats": [
   [
    1.0,
    18,
    80,
    20,
    86,
    16
   ],
   [
    2.1,
    0,
    80,
    0,
    25,
    20
   ]
  ],
  "recovery": 1.3,
  "bank": "lion",
  "contacts": [
   9,
   2
  ],
  "travel": 90,
  "window": 0.12
 },
 "M20": {
  "id": "M20",
  "title": "醉里谢幕",
  "voice": "drunk_finale",
  "beats": [
   [
    1.1,
    0,
    65,
    18,
    64,
    12
   ],
   [
    2.0,
    0,
    85,
    0,
    26,
    14
   ],
   [
    3.1,
    0,
    75,
    15,
    60,
    22
   ]
  ],
  "recovery": 1.45,
  "bank": "sweep",
  "contacts": [
   0,
   4,
   1
  ],
  "travel": 0,
  "window": 0.12
 }
}
