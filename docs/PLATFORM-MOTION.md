# 实际碰撞场景中的动画

tests/platform_motion_actor.gd 使用 CharacterBody2D、move_and_slide 和碰撞形状。以现有 225 速度、520 起跳速度、1080 重力，从地面跳到高 95 像素的单向平台，再走出平台落回地面。新二维 rig 随角色实际位置移动，只有 is_on_floor 为真时启用脚掌地面约束，实际落地事件开始相位衔接。

首次原生运行结果：landed=3（包括初始落地），reached_platform=true，air_ticks=65，air_locks=0，foot_releases=0。说明已实际跳上测试平台并返回地面，不再只是预设抛物线。

截图保存耗时导致首轮图片之间跳过多帧模拟；不能将该录制按固定 60 FPS 播放来判断流畅度。离线录制设置 max_physics_steps_per_frame=1，避免编码阻塞后的物理追帧跳过动作。该配置仅用于测试捕获，不写入游戏工程设置，也不能当作运行性能测试结果。

此处为独立测试角色，尚未接到正式 player 的攻击、闪避、受击、变身与输入逻辑。场景是碰撞实验，不是新增游戏关卡或完成的美术场景。输出目录 builds/qa/platform-motion。
