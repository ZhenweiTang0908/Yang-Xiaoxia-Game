# 图像制作与资源来源

角色及场景使用内置 image_gen 生成。角色来自用户提供的照片参考，不含原始照片文件。游戏角色为 2D 动作图集，不是 3D 网格。

## 角色提示词
Use case: stylized-concept. Production game sprite atlas on genuinely transparent background. Use attached photos as identity references for the SAME boy: short black hair, round natural face, realistic child body proportions, orange raglan sleeves cream t-shirt with small bear graphic, black knee shorts, bare feet. Detailed high quality pixel art with realistic volume and facial likeness, no chibi. EXACT 4 columns by 4 rows equally sized cells, each character centered with feet on same baseline, all face RIGHT in side-three-quarter view. No labels or grid lines. Row 1 four idle breathing frames holding a small plain silver sword. Row 2 four distinct running cycle frames with sword. Row 3 four sword attack frames anticipation, slash, extension, recovery. Row 4 jump ascending, falling, bow drawn, golden glowing empowered stance. Entire body and weapon inside each cell, generous padding, no overlap. Atlas square 1024x1024. Crisp pixel clusters, warm highlights, dark blue outlines. Transparent unused area, no floor or background.

## 最终敌人提示词（按用户简化要求重做）
Use case: stylized-concept. Production enemy spritesheet, minimalist expressive silhouette-driven pixel art for side scrolling action game. TRANSPARENT background. EXACT 4 columns by 3 rows equally sized cells, each complete sprite fully inside its own cell with generous padding. NO labels, no grid lines. All face LEFT. Row 1: same little squat sage-green stone creature in 4 poses (idle, walk, wind-up with arm back, punch). Smooth simple bean-shaped body, two short legs, two chunky arms, ONLY one dark eye slit. NO jewelry, NO gems, NO armor, NO cracks, NO scales, NO carved details. Just 3 broad muted green color shapes total, strong silhouette. Row 2: same little floating dark blue ghost with simple hood and two tiny pale eyes in 4 poses (float idle, float up, wind-up, cast); single flowing robe silhouette, 3 broad color planes, NO ornament. Row 3: same larger silent slate-blue temple guardian with plain rounded head and a SIMPLE wooden staff in 4 poses (idle, step, lift staff, swing); broad shoulders, tapered legs, 3 broad flat color planes, one pale eye slit, NO metal ornaments. Elegant restrained design, clear rounded forms, carefully controlled negative space. No texture or dithering, no surface noise, no sparkle, no glow effects, no tiny details. Clean limited palette PIXEL ART with visible square edge stepping. Animation frames consistent size and feet baseline per row.

## 最终背景提示词（按用户简化要求重做）
Use case: stylized-concept. Background asset for side scrolling pixel art game. Wide 16:9. Very restrained atmospheric minimalism inspired by quiet silhouette-driven metroidvania backgrounds. Empty mountain pass at night. 75 percent negative space: broad matte muted midnight blue sky. Only THREE simple overlapping mountain silhouettes along lower third, soft desaturated blue-green. One small pale moon in upper right, not bright huge. A SINGLE dark curved branch entering upper left corner. Background remains far away, no walkable foreground, no floor. Pixel art with crisp subtle stepped contours, broad flat color shapes, just 6 colors total. Calm, understated, elegant, readable. NO texture, NO details, NO buildings, NO stairs, NO lanterns, NO stars, NO fireflies, NO vegetation clusters, NO ruins, NO ornaments, NO glowing particles. No text, no characters, no UI. Sparse composition deliberately leaves screen quiet so character and combat stand out.

## 声音
初版音效为本项目原创离线合成，源码 tools/make_audio.py；三关版资源见下文。


## 三关升级版（v0.2）

主角 52.8 像素高（原 88 的 60%），哥哥 88 像素高。图集分别包含人形 40 帧、第三段斩击 8 帧、哥哥 24 帧、羊灵 24 帧、八类敌人 48 帧和三个 Boss 18 帧。生成图按实际行边界切分、以脚底锚定；哥哥与羊灵使用纯色底图和运行时色键材质，保留白发与幽火。

角色为 2D 精灵动画，不包含三维可编辑网格。图像由内置 image_gen 基于用户照片与明确角色设计生成；游戏包不含原始照片。

声音扩展为 94 个 WAV 音效事件/变体、一条环境声和六首原创 Ogg 曲目。探索每首 96 秒，Boss 每首 64 秒。离线合成源码 tools/make_audio_v2.py；没有抽取商业游戏素材。

### heroV2Prompt

Use case: stylized-concept. Production clean PIXEL ART sprite animation atlas, TRUE TRANSPARENT background, EXACT 8 columns x 6 rows, 48 equal cells with generous margins and identical feet baseline. Same young boy from reference pictures, short black hair, orange sleeves cream shirt small bear motif, black knee shorts, barefoot, realistic child proportions NOT oversized chibi head. All face RIGHT side-three-quarter. Plain short silver sword. Row1 eight subtle breathing idle frames. Row2 eight distinct smooth running cycle frames. Row3 eight continuous horizontal sword attack frames anticipation to followthrough. Row4 eight rising sword attack frames. Row5 eight downward heavy sword attack frames. Row6 eight poses in order: takeoff, rising, falling, landing, hurt, dash low pose, bow draw, bow release. Each full body AND weapon must fit inside its cell with 15% empty margins, NO overlap adjacent cells. No slashes or particles baked into sprites. Clear clusters and broad shading only, warm skin, face and costume resemble photo. NO text no labels no grid. Large landscape atlas 2048x1536.

### uppercutPrompt

Use case: stylized-concept. New production pixel art sprite atlas using attached boy atlas as exact character appearance reference. SAME boy, orange cream bear t-shirt, black shorts, barefoot, short black hair and face. Create EXACT 4 columns x 2 rows = EIGHT sequential frames of ONE rising sword uppercut combo attack: row1 anticipate crouching, pull sword behind, initiate upward swing, blade rises waist level; row2 blade above head, full followthrough, lower sword, return to stance. All face RIGHT. FULL BODY and sword in EACH cell, 20% transparent padding, perfectly identical body scale and feet baseline across all eight cells. TRUE transparent alpha background, NOT checkerboard art. No background color, no fx trails, no labels no grid. Simplified refined pixel clusters, proportions and costume identical to reference.

### niuPrompt

Use case: stylized-concept. Production 2D pixel art sprite atlas of Niu Daxia, using attached three photos ONLY as face identity references: preserve rectangular eyeglasses, face shape and features. CHANGE hair to shoulder length WHITE hair with large dark green dyed sections. Red simple shirt, charcoal trousers and dark shoes. Adult realistic proportions, tall slender, NOT chibi. Weapon is magical playing cards ONLY, no swords. Transparent background. EXACT 6 columns x 4 rows equal cells, 24 separate full-body sprites, ample margins inside EVERY cell and same feet baseline. All face RIGHT in side-three-quarter view. Row1 SIX sequential idle breathing/shuffling cards frames. Row2 SIX running frames hair flowing gently. Row3 SIX attack frames: draw card, fan cards, arm anticipation, throw, followthrough, recover. Row4 SIX poses: jumping, falling, casting card circle, stepping out from portal, dissolve into cards, collect cards. Clean restrained pixel art, broad flat planes, no texture/no jewelry/no ornate embroidery. Face resemblance important, green white shoulder-length hair and glasses clearly visible. No labels no grid no text no backdrop. 1536x1024 landscape atlas.

### sheepPrompt

Use case: stylized-concept. Game production pixel art animation atlas, TRUE TRANSPARENT background. EXACT 6 columns x 4 rows equal cells, 24 frames, full body in each cell with 15 percent transparent padding, same feet baseline. Same upright slightly sinister SHEEP SPIRIT swordsman in every cell: clearly sheep head with curled ram horns, long narrow pale muzzle, dark charcoal fleece body, digitigrade hooved legs, luminous pale green slit eyes, one plain curved spectral blade. No human face. Compact proportions, ominous but elegant, NO gore. All face RIGHT. Row1 six idle breathing frames. Row2 six running frames. Row3 six sword slashing frames anticipation, swing, followthrough. Row4 six distinct poses: rising jump, falling, horn charge, casting ghostflame, charged blast crouch, transformation stance. Minimalist broad 3-tone forms with light ivory horns and pale green eye/blade accent. NO jewels NO armor ornament NO texture NO smoke covering silhouette. No text no grid no labels, no extra characters, no backgrounds. 1536x1024 landscape.

### mobsPrompt

Use case: stylized-concept. Production pixel art ENEMY sprite atlas, TRUE transparent background. EXACT 6 columns x 8 rows equally sized cells, each full sprite fits cell with 15% margin, all face LEFT. Each ROW is one enemy, SIX animation states in order idle, move, anticipate, attack, hurt, dissolve. Row1 simple squat sage green stone imp with single eye slit. Row2 navy floating hooded ghost. Row3 slate blue heavy stone guardian carrying plain wooden staff. Row4 rust-brown lean monkey-like pouncing mountain creature. Row5 purple small bat with big readable wings. Row6 masked burgundy hooded dart thrower. Row7 stocky teal horned shield bearer with large plain round shield. Row8 muted ivory hooded shaman with simple staff. Broad silhouettes, 3 to 4 flat colors each, no texture no jewels no cracks no scales no ornate gear, no tiny marks. Consistent minimalist premium action platformer art. All eight types clearly distinguishable by silhouette. No labels no grid no text, no scenery, no gore. Portrait atlas 1536x2048.

### bossPrompt

Use case: stylized-concept. Production minimalist pixel art BOSS sprite atlas on true transparent background. EXACT 6 columns x 3 rows equal cells, generous 15% margins, no overlap. Every row same boss in six states: idle, moving, winding up, attacking, hurt, collapse. All face LEFT. Row1 powerful ivory antlered lantern beast, four legs, amber eye and simple amber lantern hanging from neck, plain broad forms. Row2 elegant tall dark burgundy masked wandering swordsman with pale silver short blade and long dark scarf, slim silhouette, no ornament. Row3 imposing black and indigo ram-headed spectral priest with huge ivory curled horns and plain crescent staff, long flowing robe, small violet eyes, ominous sheep god silhouette. Each body fully within cell. Three broad shade planes per character, restrained dramatic silhouettes, readable simple shapes. NO texture NO jewelry NO carved filigree NO detailed armor NO tiny decorations NO particles. No words labels grid background. 1536x768 landscape.


## 字体
Noto Sans SC，Google Fonts，SIL Open Font License 1.1。已实例化为字重 500 并裁剪为游戏所需字符。原始来源：https://github.com/google/fonts/tree/main/ofl/notosanssc
