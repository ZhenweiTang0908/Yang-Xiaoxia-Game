# 二维位置插值实验与接入审计

更新：正式场景现已采用独立显示层插值，见 [SCENE-MOTION.md](SCENE-MOTION.md)。以下保留初次实验与接入前问题记录，不代表当前仍未接入。

本地 Godot 4.7 支持 SceneTree.set_physics_interpolation_enabled。tests/interpolation_lab.gd 仅在独立实验中开启，正式 project.godot 未改变。

实验以 10 TPS、固定 60 FPS 渲染同一二维角色，记录画面中红／绿标记位置，而非仅比较逻辑坐标。180 帧中：直接移动 149 帧位置保持、最大步长 13.2 像素；插值移动 3 帧位置保持、最大步长 2.4 像素。JSON 和全部帧位于 builds/qa/interpolation；视频为 builds/qa/interpolation-comparison.mp4。这是刻意降低物理频率的诊断，不是正式游戏在 120 Hz 显示器上的验证。

正式接入尚未完成，需要一起处理：

- game.gd 镜头位置目前在 _process 中更新，应与插值路径协调。
- player.gd 骑乘位置同时在物理帧和渲染帧同步，不能直接全局插值，否则可能与牛的座位错开。
- 牛魔和刀客的闪现、坠落恢复、切关、出生位置均需要重置插值历史。
- room_features 直接绘制物理平台坐标，必须让外观与插值后的搭乘者同步。
- 投射物使用自绘世界坐标，需要单独插值显示位置，命中仍沿固定物理步长计算。
- 现有骨骼／二维网格次级动作在渲染帧运行，避免二次插值或改变原画脸颈形状。

资料：[Godot 插值接入说明](https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/using_physics_interpolation.html)、[二维与三维差异](https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/2d_and_3d_physics_interpolation.html)。
