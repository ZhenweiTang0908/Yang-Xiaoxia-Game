# 衔灯狮叟：形象方向

2026-10-26。用户已认可人物概念，正在确认视觉简化版。完整战斗设计仍在深化，尚未接入游戏。

## 用户最新美术要求

以游戏像素／马赛克式简洁性为准，靠剪影、大色块、姿态表达角色。背布纯红，不加图案；减少衣褶，去掉污渍、做旧、密集纹理。不要画成精细插画。复杂动作靠更多姿态和过渡关键帧实现，单帧仍然简洁。

保留：敦实白胡子老武人、靛青短打、红腰带、深色裤、浅色绑腿、黑布鞋、小酒葫芦；红色狮头、赭黄毛块、独角、口中暖灯。独自舞狮，只有两条人腿，短背布。

## 简化版生成提示词

工具：内置 image_gen。参考旧概念仅保留角色身份，以 builds/qa/boss-clean-sheet.png 约束游戏精简程度。

Redesign the elderly solo lion dancer as a simple pixel/mosaic-style 2D GAME CHARACTER, not a detailed illustration. Preserve stocky white bearded elder, indigo short jacket, plain red sash, dark trousers, beige calf wraps, black shoes, brown gourd, red and ochre Chinese lion head with one cream horn and small warm lamp in mouth. Remove gold floral patterns, brocade, embroidery, dirt, scratches, speckles, weathering, paper/cloth texture, fine hair, fur strands, intricate lantern lattice, detailed fingers, ornamental borders and tatters. Back cape is one plain red base color with at most one broad shadow. Jacket has only 2 or 3 major fold lines; trousers have 2 large crease shapes. Beard and lion fur are compact chunky masses. Flat color blocks, limited palette, two-tone shading, crisp pixel-stepped edges, no gradients or glossy light. Low sprite resolution enlarged with nearest-neighbor appearance. Solid blue-gray background. Four full-body studies: neutral lion held above face; crouched lion with visible supporting hands and two human legs; uncovered elder drunken fist with lion beside him; backward lean with gourd and visibly planted support foot. Consistent proportions, funny readable pose, no text.

## 当前状态

旧版带纹样概念已被用户纠正，不作为后续帧图的风格依据。新版生成后需要实际检查；概念图不等于完成的动画关键帧、游戏图集或已验证的动作。

## 已生成的简化概念

`concept-simple-v2.png`：内置 image_gen 生成的四姿态视觉草案。已目视检查：红背布无图案，衣服无污渍，毛发合并为色块，细节明显减少。仍属于概念图，尚未拆分为游戏帧图；后续帧图要继续控制少量狮额装饰点与腰间道具一致性。

## 动作图板审看记录

- `poses-backfall-study-v1.png`：16格后仰—跌坐—肩背翻滚—撑地—跪起—站稳。色块简洁，主要动作方向可辨，覆盖了单靠站姿补间无法完成的形体变化。第08到09格从背滚切到头朝下的支撑姿态仍偏急；第10到11格朝向／胸腹关系需要重新画连续侧身承接。第15与16格近似，不能把重复轮廓当作两个有效独立生产帧。此图为动作探索，非最终通过帧图。
- `poses-lion-lift-study-v1.png`：16格蹲身举狮—高举—落砸—提头。纯红背布、毛发块面保持一致。第03到04格腿伸得过快，第07到08格头壳角度跳变，需要补「伸腿半举」和「转腕下落」姿态。第11、12格握柄应在头壳内部明确承接；灯罩偏密，最终帧进一步减线。布的宽度应回收到短布标准。此图不直接用作运行时图集。

关键帧数预算与逐张清单见 `docs/lion-elder-design.md`。每张图板的16格只是请求与实际版面格数，不代表16张均已通过可用性验收。
- `poses-sweep-handstand-study-v1.png`：16格低扫—收腿—双掌支撑—倒立高脚—落脚—起身。双掌承重和高低变化清楚，服装色块简洁。第06格转背后第07格转回正侧，中间需补髋和肩的转身；第10到11格仍需补双腿离地的中间姿态。跨图板检查时腰间葫芦侧别有漂移，最终分层位置必须按同一侧固定。图板用于确定动作语言，不作为合格生产图集。
