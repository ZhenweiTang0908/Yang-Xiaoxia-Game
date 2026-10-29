# 衔灯狮叟（第五战）交接文档

生成时间：2026-10-26。仓库：`/Users/niuniutang/Code/Yang-Daxia`（Godot 4 横版动作游戏）。所有改动**未提交、未导出、未部署**。

## 0. 一句话现状

第五个 Boss「衔灯狮叟」的**逻辑、判定、声音、参数、路线接入都已完成并通过测试**；他前半战顶着狮头舞狮，后半战把狮头放地上打醉拳，共 20 招、两阶段、34 个台词事件（68 句）、独立配乐与逐段音效。

**唯一没完成的是美术验收**：动作图仍是 305 张草稿帧（0 张签字验收），其中 `M15` 那组源图本身有两格被画布上边缘切掉、还带重复酒壶，必须重画；另外还没有任何一张重切后动作的**实机截图**被人眼看过。

## 1. 必须先知道的硬性约束

- **跑测试一律走包装脚本**，不要直接 `Godot --headless`：
  `.agents/skills/godot-headless-test/run_test.sh tests/<name>.gd <超时秒>`
  它会加硬超时、见 `SCRIPT ERROR` 立刻杀进程、拒绝重复启动。图形截图必须 `--audio-driver Dummy`、`open -g` 后台启动、跟踪真实 Godot PID、带超时清理（细节见该 skill）。
- **用户没说「部署」就不要打包/导出/部署**（见 `.agents/skills/release-deploy/SKILL.md`）。
- **沙箱里 `user://` 不可写**（实测 `FileAccess.open` 返回错误 12，路径 `~/Library/Application Support/Godot/app_userdata/羊小侠/`）。因此 `tests/save_store.gd`、`upgrades.gd`、`relics.gd`、`stage_results.gd` 在沙箱内**必然失败**，是环境问题不是代码回归，需要在真实环境或提权后复跑。
- 本机存档 `journey_mode` 是 `relaxed`（承伤 0.7 倍）。任何断言具体伤害数值的测试都必须显式设置难度，否则会莫名其妙差 30%。

## 2. 用户对这个 Boss 的原始要求（别丢）

> 「可以，我完全认同。你可以继续扩展，多看一些醉拳方面的资料，把它做得更像、更有趣、更逗，出招更怪异奇特、更有趣。他的形象一定要做好。他的动作我感觉会比较复杂，你要把关键帧做好，多做一些过渡关键帧，不要那么突兀。你能多画图就多画图。」

后续还专门纠正过一次美术方向：**不要堆细节纹理**（背布一块纯红就好、衣褶少一点、不要脏东西），要「马赛克简洁性」，不要画成精细插画。这条已经写进 `.agents/skills/create-boss/SKILL.md` 第 4 条和「自查」清单，务必遵守。

完整设计在同目录 `docs/lion-elder-design.md`（含 20 招表、逐招姿态目录、68 句台词、灵感来源与链接、五项质量要求、验收目标）。**设计已获用户确认，可以直接实现，不要再问一遍。**

进度与踩坑记录在 `docs/lion-elder-progress.md`。

## 3. 已经实现并通过验证的部分

| 测试 | 检查数 | 覆盖 |
|---|---|---|
| `tests/lion_combat.gd` | 112 | 每招前摇不伤人、部分命中、单段只结算一次、高低躲法、破势、阶段、死亡/暂停清场、转阶段放狮头、空挥懊恼 |
| `tests/lion_fairness.gd` | 4662 | 20 招左右两侧接触帧、像素轮廓可命中、无效窗口、暂停/命中停顿/死亡冻结、选招合法性、固定距离命中 |
| `tests/lion_art.gd` | 866 | 时间轴、锚点、socket 映射、非法请求保留画面 |
| `tests/lion_audio.gd` | 678 | 197 个音效事件、逐招分段、暂停、去重、不抢哥哥语音 |
| `tests/lion_route.gd` | 19 | 第五战接入连战、结算、存档 |
| `tests/lion_tuning.gd` | 348 | F2 参数约束与持久化 |
| `tests/lion_dialogue.gd` | 104 | 34 组 68 句都有真实调用点（不是只存在于 JSON） |
| `tests/lion_import_ready.gd` | 1087 | 353 张帧图全部有 `.import` 与 `.ctex` |
| `tests/lion_fight_sim.gd` | 6 | 真实主循环打完整场（约 74 秒、4400+ 帧），两阶段+休整+结算；支持 `LION_SEED` |
| `tests/lion_counterplay.gd` | 12 | 多段招第一段挨打不会吃掉后续段 |
| `tests/boss_phase_shift.gd` | 11 | 通用阶段逻辑未被改动破坏 |

已用种子 7/19/88/131 各打过一整场，都能正常结束。

## 4. 文件地图

**逻辑与数据**
- `scripts/actors/lion_elder.gd` — Boss 本体：状态机、选招、接触判定、两阶段、空挥懊恼、放狮头
- `scripts/actors/lion_moves.gd` — 20 招定义（id/title/voice/beats/bank/contacts）
- `scripts/animation/lion_elder_visual.gd` — 帧加载、镜像、像素轮廓判定 `silhouette_intersects`
- `scripts/animation/lion_pose_timelines.gd` — 每招姿态时间轴（把编排时间映射到实际招式时间）
- `scripts/core/lion_audio.gd` — 音效路由、台词冷却（12 秒）
- `scripts/core/balance.gd` — 全部数值（`lion_*` 开头的键），F2 面板直接读 SCHEMA
- `data/bosses/lion_elder.tres`、`data/arenas/boss_5.tres`

**美术管线**
- `art_source/lion_elder/production/*.png` — 每一招/每套动作的源图（整张 sheet）
- `tools/import_lion_production.gd` — **核心切图工具**（详见第 5 节）
- `assets/art/lion_elder_frames/<bank>/frames.json + NN.png` — 切好的帧与清单
- `tools/lion_contact_sheet.gd` — **离线审图**：合成每套动作检查图，带地平线与支撑点，无头可跑
- `tools/lion_measure.gd` — 用出货判定量出某招命中瞬间画面真正覆盖的范围
- `tools/lion_timeline_audit.gd` — 检查硬切与命中前停顿
- `tools/lion_bridge_audit.gd` — 检查网格过渡是否追不上帧间隔
- `tools/lion_stance_audit.gd` — （慢）逐招扫「近身之内是否总有安全站位」
- `tools/run_lion_capture.py` + `tests/lion_capture.gd` — 后台静音实机截图（逐招命中帧 + 转阶段逐帧）

## 5. 切图管线的关键约定（踩坑换来的，别推倒重来）

1. **按连通域分配，不用等分网格**。生成的 sheet 里姿势间距不均，等分会把手臂、披风、狮头切进隔壁格，画面出现多余碎片。现在整张 sheet 先做一次连通域标记，再按「中心落在哪一行/列」归给对应姿势，每一帧只复制自己的像素。
2. **零散道具归最近的身体**。`M15` 的酒壶是脱离身体的一块，按最近身体分配；并用 `ONE_PROP_BANKS` 保证一格最多带一件道具。
3. **锚点 = 支撑脚所在的最下四行加权横坐标**，`baseline` = 身体包围盒底部。换成整体重心会让所有手调判定框错位，**不要再改**。
4. **判定框要贴着画出来的东西**。重切后 `M03` 的鼻子落到了原点另一侧，原判定框整段落空，已改成覆盖画出的狮头（`lion_M03_0_near=-124`、`far=22`）。以后任何重切都要重跑 `lion_fairness`。
5. **切完必须重跑导入**，否则导出包缺图：
   `timeout -k 5 300 /Applications/Godot.app/Contents/MacOS/Godot --headless --audio-driver Dummy --path . --editor --import`
   然后用 `tests/lion_import_ready.gd` 验证。编辑器里直读 PNG，**看不出**这个缺失。
6. **网格过渡不要瞎调**：量过 238 段相邻姿势里只有 6 段间隔短于过渡时长，说明「糊影」不是主要问题，保持现状。

## 6. 还没做完的（按优先级）

**P0 — M15 必须重画。** 源图 `art_source/lion_elder/production/M15-v1.png` 有两格被画布上边缘切掉（头顶断掉），且那两只是**连在一起的一整块**（壶＋红绦＋另一只壶同属一个连通区），切图拆不开。可直接用的提示词：

> Repaint this same elderly Chinese lion-dance master's gourd-tossing action sheet with the SAME character design: bald head with white topknot, long white beard, navy short jacket with open chest, wide dark trousers, red sash, straw leg wraps, dark shoes, one plain red back cloth, one brown waist gourd. Keep the flat limited-color pixel sprite style. CRITICAL: a 4 column by 3 row grid of TWELVE separate full-body sprites; every sprite completely inside its own cell with at least 15% clear margin on all four sides, nothing touching the image border; equal size, all facing LEFT, both feet on the same ground line unless airborne. Read row-major: standing holding gourd; lift to chest; raise overhead; cock arm back; swing forward; gourd released upward; gourd high above upraised hands; watching it overhead; catch position; lowering it back; tipping head back for a swig; wiping beard, amused. One gourd only per frame. Coarse clean pixel art, big simple shapes, few broad folds, plain solid color cloth, no patterns, no ornaments, no dirt, no texture, no gradients, no grid lines, no text, real transparent background.

存成 `M15-v2.png`（切图脚本会自动优先用 `-v2`），然后切图 → 导入 → `lion_contact_sheet` 看图 → `lion_art`/`lion_fairness`/`lion_combat`。

**P0 — 实机截图验收。** 重切后的画面一次都还没被人眼看过。恢复额度后立刻跑：
`.venv/bin/python tools/run_lion_capture.py`（需提权；后台静音启动并自行清理进程）
产物在 `builds/qa/lion-elder/`：`contact-M01..M20.png`、`transition-00..07.png`、`transition-complete.png`、`production-lion-idle`、`production-elder-idle`。
重点看：脚是否落地、狮头比例、有没有多余碎片、左右朝向、左右手/壶是否唯一、和玩家及其他 Boss 并排时的体量。

**P1 — 逐招目视。** `tools/lion_contact_sheet.gd` 会为 27 个 bank 生成 `builds/qa/lion-elder/sheet-<bank>.png`，带红色地平线与黄色支撑点。**支撑点必须落在脚上**，落在别处就是锚点错了。

**P1 — 跑一次慢审计。** `tools/lion_stance_audit.gd`（约 2–5 分钟）确认每招在近身范围内都有安全站位；它很慢，所以没放进常规测试。

**P2 — 休整动作多样性。** 设计里写了「拨狮眼／抖肩／揉腰／找观众，最近 3 次不重复」，现在只有一套休整姿势。要做需要先看图确认 `reactions` bank 里哪几帧适合，别盲配。

**P2 — 272 张姿态预算。** 目标 272 张独立姿态，现在 305 张草稿（含重复与不合用的），**0 张签字验收**。清单在 `docs/lion-elder-design.md` 的「逐招姿态目录」。

## 7. 常见陷阱

- **别写无界 `while boss.t<at` 循环**。当 `game.state!="playing"` 或 `hitstop>0` 时 `_physics_process` 会提前 return、`t` 不前进，直接死循环（本轮 `lion_counterplay` 就因为它在 180 秒超时）。要么按帧数循环，要么加 `guard` 计数并每次把 `game.hitstop=0`。
- **Godot 4 没有全局 `seed()`**，用 `rng.seed=...`。
- **单 Boss 场结算会压后最多 6.5 秒**（等败北台词说完），测试里要等够。
- **`lion_fairness` 的选招扫描要清 `stagger_left`/`stagger_kind`**，否则空挥懊恼会打断选择，误报「选招不合法」。测试的 `reset()` 也要清 `stagger_kind`。
- **控制台出现 `LION_ART_RAW_FALLBACK`** 说明有帧没导入，导出会缺图。
- 353 张 PNG = 305 张生产帧 + 48 张旧 study 帧（`lion`/`backfall`/`sweep` 是早期草图，仅用于预览）。

## 8. 当前阻塞（会自己恢复）

2026-10-26 12:19 UTC（北京时间 20:19）之前，**图像生成**和**需要提权的图形截图**都会被拒：

- `image_gen` 返回：`http 429 ... Codex main account is blocked by the main-account quota policy (5h ≥ 90%, weekly ≥ 98%)`
- 提权跑 `tools/run_lion_capture.py` 返回：`Automatic approval review failed: You've hit your usage limit.`

无头测试不受影响，可以照常跑。恢复后按第 6 节的 P0 顺序做。

## 9. 立刻可以执行的命令

```bash
# 狮子全量回归（约 40 秒）
for t in lion_combat lion_fairness lion_art lion_audio lion_route lion_tuning lion_dialogue lion_import_ready lion_counterplay boss_phase_shift; do
  .agents/skills/godot-headless-test/run_test.sh tests/$t.gd 300
done

# 整场对战（可换种子）
LION_SEED=7 .agents/skills/godot-headless-test/run_test.sh tests/lion_fight_sim.gd 300

# 重切 + 导入 + 审图
.agents/skills/godot-headless-test/run_test.sh tools/import_lion_production.gd 300
timeout -k 5 300 /Applications/Godot.app/Contents/MacOS/Godot --headless --audio-driver Dummy --path . --editor --import
.agents/skills/godot-headless-test/run_test.sh tools/lion_contact_sheet.gd 180
```

## 10. 判断完成的标准

按 `docs/lion-elder-design.md` 的「实施后的验证目标」逐条对照。当前**不满足**的是：每招真实渲染视频/截图逐帧检查、272 张有效独立姿态、并排对照其他 Boss 的画风、真实手动游玩的手感评估。这些都需要**人眼看图**，测试通过不等于美术完成。
