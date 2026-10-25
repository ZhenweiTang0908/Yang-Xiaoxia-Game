# 简洁像素版牛大侠与牛魔

本版替代早期牛人、六臂和三叉戟设计。使用内置 imagegen 生成，运行时以色键去除洋红背景。

- `assets/art/v3/niu_human.png`：两臂普通人、眼镜、绿白齐肩发、卡牌。
- `assets/art/v3/bull.png`：四足黑牛，站立、蓄力、奔跑、刹停和受击。
- `assets/art/v3/rider.png`：羊小侠骑乘坐姿。

## simpleNormalPrompt

Create a production pixel-art animation spritesheet, 1536x1024, exactly 6 columns x 4 rows of equal 256x256 cells. One same HUMAN male card fighter per cell, facing RIGHT in side/three-quarter platform-game view. This is a radical simplification of the reference: preserve ONLY shoulder-length white hair with ONE broad muted dark-green section, simple black glasses, one tiny mole below the mouth. Completely ordinary human anatomy: TWO arms, TWO human legs, normal shoes, NO horns, NO animal body parts, NO scales. Plain dark charcoal short jacket over plain muted red shirt, plain dark trousers, no patterns, no jewellery, no belts or tassels. Slim adult real-ish proportions, not huge head. Clean authentic LOW RESOLUTION pixel art, each figure looks authored at 32x64 pixels then nearest-neighbor enlarged 3x, chunky deliberate square clusters, ONLY 10-12 flat colors TOTAL, one shadow tone per material. Very simple silhouette, no individual hair strands, no shading gradients, no render, no fine illustration. Each figure approximately 170-185 pixels tall in its 256 cell, feet at y224 within every cell, ample magenta padding. Uniform pure #FF00FF background. Row1 six idle card-shuffling poses; Row2 six running cycle poses with alternating feet and subtle hair movement; Row3 six card throw poses anticipation, draw, extend, release, recover, settle (one tiny plain card only, no effects); Row4 jump up, landing crouch, fan-card stance, stepping out, collecting cards, hurt recoil. No weapons except plain little rectangular cards, no built-in trails, no glows, no text, no grids. Make it as graphically restrained as a classic 16-bit platform game, not a detailed fantasy character illustration.

## simpleBullPrompt

Create a production animation spritesheet, 1536x1024, EXACTLY 4 columns x 2 rows of equal 384x512 cells, 8 images of the SAME simple quadruped bull facing RIGHT, full body side view. A stocky dark charcoal BULL on FOUR hooved legs, short muzzle, small plain ivory horns only on the bull, short thin tail, one muted jade eye. NO human features, NO arms, NO clothes, NO armour, NO saddles, NO jewellery, NO symbols, NO flames, NO particles. Broad plain back to seat a small rider later. Authentic low-resolution 16-bit pixel art: each bull looks drawn at 64x40 pixels and enlarged nearest-neighbor 4x; chunky square clusters, only 6 flat colors total, one dark body mass plus one large lighter plane, absolutely no fur texture or tiny highlights. Bull about 280px wide and 170px high in each cell, centered horizontally, hooves baseline y380 in each cell. Pure uniform #FF00FF background and ample padding. Cell order row-major: 0 calm standing, 1 head lowered preparing charge, 2 gallop contact, 3 gallop push-off, 4 gallop airborne with tucked legs, 5 gallop extended legs, 6 braking with lowered head, 7 hurt recoil. These are readable animated poses, keep proportions and back height consistent. Empty surroundings, no floor, no captions, no borders. Prioritize simplicity and recognizable bull silhouette over detail.

## simpleBullCleanupPrompt

Edit this spritesheet ONLY: replace the entire black/grey background and all soft glow halos with a perfectly flat solid RGB #FF00FF chroma-key background. Remove every lighting glow around horns and hooves. Preserve the exact same eight bull sprites, their silhouettes, positions, sizes and four-column two-row grid. Keep flat, simple charcoal pixel-art cattle with plain ivory horns and one green eye; do not add details. No gradients anywhere outside the solid bull silhouettes. Clean hard pixel edges. Output 1536x1024.

## simpleRiderPrompt

Make a single 1024x1024 pixel-art game sprite of the reference little boy, in a SEATED RIDING pose viewed from the RIGHT-facing side, ready to place on the back of a bull (DO NOT draw the bull). Black short hair as one dark shape, cream shirt with orange short sleeves, plain black shorts, bare feet. Knees bent, one near-side shin hangs down, other leg straddles an invisible animal back; hands forward resting lightly for balance, torso slightly leaning forward. No sword, no weapons. Minimal 16-bit pixel style, visible square clusters like a 32x40 sprite enlarged 12x, only 10 flat colors, no shirt graphics, no texture, no fine hair or realistic shading. Boy occupies central 400x480px, whole body with generous empty pure #FF00FF background. Preserve youthful face and outfit colors of reference but simplify heavily. No text, no bull, no chair, no effects.

