> 历史设计，已被 SIMPLE-BROTHER-ART.md 与 NIU-DEMON.md 的简洁人形／四足牛方案替代。

# 牛大侠牛灵外形更新

使用内置 image_gen 编辑原动作图集，以用户哥哥照片为脸部参考。保留眼镜、嘴下痣、绿白齐肩发及卡牌动作；改为牛角、人形上身、腰部渐变牛毛、直立牛腿与分趾蹄、鳞片手臂、暗紫近黑披风。沿用 88 像素身高。

资源：assets/art/v2/niu.png。原现代服装版本保存在 builds/archive/niu-modern/niu.png。

披风颜色按语音中的描述暂解释为暗紫近黑，下半身按直立双腿牛形处理。

## 生成提示词

Use case: identity-preserve. Edit target image 1 is an existing 6 column x 4 row game character animation atlas. Image 2 is adult human face identity reference; IMPORTANT preserve his glasses, natural face proportions and single dark mole centered just below lower lip on upper chin. Redesign EVERY frame of image 1 into the SAME mythic bovine spirit card magician Niu Daxia. Keep shoulder-length white hair with large dark green sections, human face and glasses, add two clear ivory BULL HORNS sweeping outward then upward (not curled ram horns). Remove red T-shirt completely. Human upper torso wears an open sleeveless mantle / cloak coat in very dark aubergine purple and charcoal black; exposed chest modest, no modern shirt. Arms show a FEW broad overlapping dark jade scales on shoulders and forearms, no dense texture. At waist human skin gradually transitions into dark brown/charcoal bovine fur. Lower body is visibly bovine with two strong digitigrade cattle legs ending in SPLIT HOOVES, and a short bull tail; no trousers, no human shoes. Upright two-legged half-human half-bull anatomy, NOT four-legged centaur. Cloak falls behind hips but does not hide bovine legs or waist transition. Keep throwing green-white magical playing cards, no sword. Restrained silhouette-driven pixel-art sprite rendering with large clean shapes, limited colors and no ornamental clutter. Same 24 distinct animation poses and exact ordering as target: row1 six idle/card handling, row2 six running poses, row3 six draw/fan/throw/cast/recover poses, row4 jump/landing/rune/portal emergence/card dissolve/crouch rune. Every whole character INCLUDING horns, hooves, cloak and card effects fits INSIDE its own cell with 20px padding. Exact image dimensions 1536x1024, six equally spaced 256px columns and FOUR equally spaced 256px rows. Feet baseline 235px within every cell except airborne and dissolving poses. Preserve a uniform body size across all frames, no overlap between neighboring cells. Background is flat solid pure #FF00FF magenta for runtime chroma key, NO checkerboard, NO cast shadows, NO floor, no text/labels/grid. Entire torso+head remain recognizably human; cow identity comes from horns, waist transition and lower body.
