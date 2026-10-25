# 四小关与动作资源修复

三个大关各四小关：地面阶梯与屋顶路线、断桥渡台与升降台、压板门与机关庭院、Boss 前庭与竞技场。跳关支持第三小关，兼容旧第七小关入口存档。

Boss 图集的 18 个动作现为独立透明 PNG，按连通区域清除相邻动作残片。运行时不再从原图集裁切。检查图：builds/qa/boss-clean-sheet.png。

羊小侠实际加载 assets/animation/hero_blender.glb，包含 17 根骨骼与 12 个动作；源文件 art_source/hero/yang_xiaoxia_refined.blend。保留原有脸部贴图，收窄躯干与四肢。

牛大侠采用保留原画的 Blender 2.5D 网格骨骼流程，运行时使用 assets/animation/brother_blender.json 中导出的网格与动作曲线；源文件 art_source/brother/niu_daxia.blend。不是完整体积三维角色，主要姿势仍来自原画，连续曲线负责次级动作。

守灯兽扑击为落地碎石，横扫为浅色角刃弧光，地面冲击为推进石浪。保留其他 Boss 的火焰攻击。

已验证：基础集成 53 项、升级检查 24 项、跳关 40 项、移动平台承载 2 项、骑乘对齐 18 项。并逐张检查 Boss 18 张姿势。未测定实际首次通关时长，未做 Android 真机验证。
