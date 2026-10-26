# 骑士攻击扩充验证 · 2026-10-25

实现六招：三步逼阵、回缰挑枪、贯甲进刺、蹬踢接刺、退步双矢、交叉双斩。原有两阶段、枪气节奏、封葫芦和牛大侠骑乘保留。12张透明手绘关键姿态沿用旧Boss的二维网格渲染，18个独立物理音效复用项目CC0素材。参数面板新增6项前摇及6项伤害。

通过：
- `tests/knight_arsenal.gd`：61项；覆盖前摇、伤害/范围、突进单次结算、反跳判定、两箭独立锁向和实际命中封印、返斩提前锁向、AI可达、连招间隔、死亡取消。
- `tests/knight_boss.gd`：70项；枪气、阶段与葫芦回归。通关次数断言改为相对先前次数加一，避免测试流程前面已完成挑战时误报。
- `tests/knight_painted.gd`：63项；原画风、透明帧、枪气抬手与命中、弓箭出手点、下马、物理命中音。
- `tests/mount_rescue.gd`：36项；牛大侠接人、跳下和枪气判定。
- `tests/demon.gd`：47项；牛大侠技能与调参。
- `tests/rider_alignment.gd`：骑乘对齐，0失败。
- `tests/knight_fight_sim.gd`：真实循环经过马战、下马、步战和胜利；0失败。
- 原生导出PCK中再次运行新招61项，全部通过；原生应用启动并正常退出。

实机画面检查修正了突进枪、首段横斩的武器高度，保证枪尖/刀刃与腰部命中区一致。双箭瞄准以实际放箭姿态的弓位置计算。截屏与视频保存在 `builds/qa/knight/arsenal-*.png` 和 `knight-arsenal-actions.mp4`。

产物：`builds/macos/羊小侠.app`、`builds/macos/YangDaxia.zip`、`builds/web/index.html`。macOS及Web导出成功；Web本轮完成导出，未另做浏览器交互验收。测试退出时Godot仍输出资源未释放提示，环境仍有CA及编辑器设置路径的提示；没有脚本解析或运行异常。
