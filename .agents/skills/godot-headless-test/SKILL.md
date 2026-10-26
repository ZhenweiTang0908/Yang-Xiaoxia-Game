---
name: godot-headless-test
description: Run this project's Godot tests and screenshot/render/video captures safely with timeouts, SCRIPT ERROR cleanup, silent audio and background launch. Use whenever running, rerunning or writing a test or capture script in Yang-Daxia, including graphical screenshot runs without --headless.
---

# Godot 无头测试

本项目的测试是 `extends SceneTree` 的脚本（`tests/*.gd`），用 `--headless --script` 运行，结束时调用 `quit()`。

## 为什么需要这个 skill

GDScript 运行时出错（`SCRIPT ERROR`）只会中断当前协程，**不会退出进程**。`run()` 里的 `quit()` 永远执行不到，Godot 会一直以 50% 以上的 CPU 空转。2026-10-25 曾有 6 个这样的进程空转约 19 小时，导致电脑严重发热。`tests/` 下还有一些脚本根本不调用 `quit()`（比如 `*_gait*.gd`、`*_timeline.gd`、`interactive_motion_*.gd`），它们是实验或交互用的，同样不会自己结束。

## 规则

0. **默认后台静默启动，不抢前台、不开声音**：
   - 普通测试优先使用真正的 `--headless`。本机 Godot 的该参数等价于 `--display-driver headless --audio-driver Dummy`，不会创建测试窗口，也不会向音频设备播放声音；现有包装脚本已启用它。
   - 不要为了跑测试打开编辑器、通过 Finder 双击游戏，或主动激活 Godot 窗口。Shell 的 `&` 只表示后台进程，不能保证图形窗口不抢焦点；`--quiet` 只控制日志，不是静音。
   - **Codex 为截图启动的游戏窗口也适用，不能因为没用 `--headless` 就绕过本 skill。** 截图、渲染验证或录制需要图形模式时，启动命令默认必须显式传入 `--audio-driver Dummy`，从启动之初静音，不能等加载场景或播放音乐后再静音。
   - **图形截图默认请求后台启动。** macOS 通过 Launch Services 启动时使用 `open -g` 请求不切换前台，且必须继续跟踪实际 Godot 进程并落实原有超时、错误监控和清理，不能只监控很快退出的 `open` 进程。自动截图脚本应尽早在加载游戏场景前设置 `root.unfocusable = true`，避免后续窗口获取焦点；这个设置发生在进程启动后，不能单独保证启动瞬间不抢焦点。不要调用 `grab_focus()`、系统激活命令或把窗口置顶来截图。
   - 优先用 Viewport 图像保存截图，无需把游戏切到前台。不要为避免弹窗而盲目改用 `--headless`：其 dummy 渲染不能替代真实渲染截图。也不要默认最小化窗口，以免影响渲染。图形窗口可能仍然可见，后台启动不等于没有窗口；无法可靠避免抢焦点时如实说明，不承诺绝不抢前台。
   - 只有用户明确要求检查声音时才启用真实音频；不要修改系统音量或游戏的持久音量设置。导出包测试同样遵守这些默认规则。

1. **不要直接运行 `Godot --headless ...`**，一律通过包装脚本运行，不管是测试还是导出的游戏包：
   ```bash
   .agents/skills/godot-headless-test/run_test.sh tests/relics.gd
   .agents/skills/godot-headless-test/run_test.sh tests/relics.gd 120   # 自定义超时（秒），默认 300
   ```
   它会：
   - 设置硬性超时，超时后强制结束
   - 日志里一出现 `SCRIPT ERROR` 就立刻结束进程，不再等到超时
   - 拒绝重复启动正在运行的同一个测试
   - 打印结果和日志摘要，日志写在 `$TMPDIR/yang-daxia-tests/<name>.log`

   退出码：`0` 通过、`1` 测试报告失败、`2` 脚本错误、`124` 超时。
   需要测试导出包或 `--main-pack` 这类非 `--script` 的运行方式时，也必须加超时：`timeout -k 5 300 <godot 命令>`（Homebrew 已安装 `timeout`）。

2. **跑完后检查有没有残留进程**，尤其是中断过命令或在后台跑过测试之后：
   ```bash
   pgrep -fl "Godot --headless"
   ```
   有残留时先看清楚命令行和启动时间（`ps -o pid,lstart,args -p <pid>`）。确认是本项目遗留的测试进程后再 `kill <pid>`，不要误杀用户自己打开的 Godot 编辑器。

3. **编写新测试时**：
   - 所有正常路径的结尾都要调用 `quit(0 if failures.is_empty() else 1)`
   - 在访问数组下标、`load()` 结果等可能为空的地方，先用 `verify()` 检查，失败就提前 `quit(1)`，不要让脚本因空值报错
   - 打印一行 `<NAME>_RESULT checks=... failures=...`，包装脚本会把它摘出来显示
   - 只用于交互或录制的脚本不要放进批量测试，要运行时也必须走包装脚本并设置超时

4. **批量运行时串行执行或限制并发数**（M2 只有 8 个核心，每个 Godot 进程约占 0.5 到 1 个核心），不要一次在后台起一大批。
