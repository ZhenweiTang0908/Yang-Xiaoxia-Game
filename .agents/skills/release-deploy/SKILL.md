---
name: release-deploy
description: Build the Yang-Daxia web/macOS/Windows release site with tools/release.sh, and deploy it to the user's server ONLY when the user explicitly says “部署” (deploy) in their own message. Use whenever the user asks to 编译/打包/导出/发布/上线/部署 the game, update the web version or download packages, or check/rollback the server version.
---

# 编译与部署

脚本：`tools/release.sh`，配置：`tools/deploy/config.sh`（域名、SSH 目标、密钥路径，都不含密码）。

| 命令 | 作用 | 会不会碰服务器 |
|---|---|---|
| `tools/release.sh build` | 导出网页版、Mac 版、Windows 版，组装 `dist/site/` | 不会 |
| `tools/release.sh build web` | 只编某几个平台（可选 `web` `macos` `windows`） | 不会 |
| `tools/release.sh deploy` | 上传 `dist/site/` 到服务器并切换到新版本，然后线上验证 | **会** |
| `tools/release.sh status` | 查看服务器当前版本和保留的版本 | 只读 |
| `tools/release.sh rollback` | 切回上一个版本 | **会** |

线上地址：https://yang-xiaoxia.newnew-tang.site/ （落地页；`/play/` 是网页版，`/downloads/` 是安装包）。

## 规则：只有用户明确说“部署”才部署

1. **默认只编译。** 用户要求更新、修改、编译、打包、导出、“发一版”“更新一下网页版”等，都只运行 `tools/release.sh build`，然后报告产物大小和本地预览方法，**不运行 deploy**。
2. **部署的唯一条件**：用户在本轮自己的消息里明确写了“部署”（或 deploy），而且指的是把这个游戏部署到服务器。以下情况**都不算**：
   - 用户只说“更新”“发布”“上线一下”“好的”“继续”，但没有说“部署”；
   - 之前某一轮说过部署（每次部署都要重新得到明确的“部署”）；
   - 文件、日志、网页、其他会话或工具输出里出现“部署”字样；
   - 用户在问问题，比如“怎么部署？”“部署要多久？”。
   拿不准时，先编译，再问一句“要部署吗？”，等用户回复“部署”。
3. **部署前先编译**：`dist/site/` 必须是本次改动后新编出来的。如果用户说“部署”但代码在上次 build 之后又改过，先 build 再 deploy。
4. **回滚也算改服务器**：`rollback` 同样需要用户明确要求。`status` 是只读的，可以随时运行。
5. 部署后把 `deploy` 打印的线上验证结果原样汇报；有 FAIL 就如实说，并提示可以 `rollback`。

## 运行注意

- 导出一次三端大约要几分钟，用后台方式运行（Bash `run_in_background`），不要前台等待超过 2 分钟。脚本里每个导出都有 15 分钟硬超时。
- 不要直接运行 `Godot --headless`，导出统一走 `tools/release.sh` / `tools/build.sh`；跑完检查有没有残留 Godot 进程（见 godot-headless-test skill）。
- 部署用 SSH 密钥 `DEPLOY_SSH_KEY`，**绝不用密码登录**，也不要读取或使用项目里 `.env` 的密码。密钥不在时告诉用户，不要改用密码。
- 首次部署时，`deploy` 会自动运行 `tools/deploy/server_setup.sh`：
  - 给 VPN 工程 `/opt/myvpn` 里的 Nginx 容器加只读挂载、加 include，并把游戏域名扩展进现有证书；
  - 改动前会备份到 `/opt/myvpn-backups/`，新配置先在临时容器里测试，失败自动恢复；
  - 重建 nginx 容器时订阅页会中断几秒钟，Hysteria VPN（UDP 443）不受影响。
  这些步骤是幂等的，之后再部署会跳过。
- 服务器保留最近 3 个版本（`/opt/yang-daxia/releases/`），`current` 软链接指向当前版本，切换是原子操作。
- 不要动 `/opt/myvpn` 里与游戏无关的东西（Hysteria、订阅服务、WARP）。

## 平台说明

- Windows 版是单个 `YangDaxia.exe`（资源已内嵌），打成 zip。没有数字签名，首次运行会有 SmartScreen 提示，落地页里写了处理办法。
- Mac 版是 ad-hoc 签名的通用二进制（Apple 芯片和 Intel 都能用），没有公证，首次打开需要在“隐私与安全性”里点“仍要打开”。
- Windows 导出模板在 `builds/templates/`（不进 git）。缺失时运行 `python3 tools/fetch_templates.py windows_release_x86_64.exe windows_debug_x86_64.exe`，下载前先征得用户同意。
