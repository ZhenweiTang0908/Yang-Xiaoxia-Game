# BOSS 台词与双配音

四位 BOSS 共 117 句台词，中文对白按人物和战斗事件区分。守灯兽 16、渡影刀客 22、噬月祭主 24、断誓枪骑 55。骑士原有 36 句保留，增加 19 句，覆盖飞鹰、上古神兵、弓箭等技能。

默认 AI 配音，设置 → 声音中可选择 AI 配音或经典配音，点击会试听。选择随存档保留；无 AI 文件时回退经典配音。牛大侠声音不改。原有 37 个 WAV 不覆盖，校验值见 data/voice/legacy_checksums.json；新增台词也补齐经典音色。

普通台词间隔至少 12 秒，同组连续选择不重复；开场、阶段变化和败退可以优先播放，但不抢牛大侠的台词。字幕沿用画面底部，不增加技能文字警告；对白时音乐轻微压低。

数据源为 data/voice/boss_dialogue.json，通过 tools/compile_boss_dialogue.py 编译 Godot 常量。tools/generate_boss_voice.py 只调用语音接口，参考用户指定 tutorial-video-generator 的 ENV、请求和 WAV 检查方法，不生成视频，不使用浏览器。只在进程内读取密钥，不写入项目、清单或日志。

音频从主模型 gemini-3.8-flash-lite-tts 生成，每句最多一次主模型、一次 gpt-4o-mini-tts / cedar 备用调用。缓存、原始响应和失败记录放在 /private/tmp；仅处理后的游戏 WAV 进入 assets/voice/ai。音色分别为 Algenib、Schedar、Charon、Orus。检查 WAV/嵌套 WAV、时长、静音、持续削波与尾部异常，再统一为 48kHz 单声道 PCM 并做轻量音量与尾部淡出处理。

## 实际生成与验证

117 句全部由 gemini-3.8-flash-lite-tts 返回，无备用调用，本轮按威胁感表演指导重新生成，总时长 354.6 秒（逐句时长见清单）。原始返回/缓存留在临时目录；可复核的脱敏来源、音色、时长与 SHA256 清单位于 data/voice/ai_manifest.json。新增 81 句，原有骑士 36 句也生成对应 AI 版本。原有 37 份录音逐个校验保持不变。

本轮对白检查覆盖全部音频、事件触发、字幕、冷却、避免连续重复、不抢牛大侠声音、设置内实际试听、模式保存与新旅途保留。设置截图见 builds/qa/interface-settings.png；四位 BOSS 的实际生成试听串为 builds/qa/boss-voice-samples.wav。

本轮追加角色表演 instructions 和 8 条短促发力喊声；效果来源清单为 data/voice/effort_manifest.json，新试音为 builds/qa/boss-threatening-samples.wav。音乐与逐刀音效说明见 docs/scene-combat-audio.md。
