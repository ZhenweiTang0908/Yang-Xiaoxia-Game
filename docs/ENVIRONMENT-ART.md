# 场景与火焰升级

内置 imagegen 生成并接入的资源：
- assets/art/environment/vistas.png：四幅场景（月下山门、雾林、幽钟祭坛、断桥）。
- assets/art/environment/props.png：八种环境贴图。关内按区域选择地标并进行视野裁剪，碰撞地形保持原有固定路线。

喷火与地火采用独立四帧动画贴图（见 FIRE-ART.md）；电弧、落刃、斩弧与碎屑采用代码绘制的动态轮廓。噬月祭主保留十招，将原灵束改为固定朝向的焚魂吐息（1.2秒预兆，330像素距离，0.85秒持续），地裂改为短时地火。伤害仍通过统一判定与无敌帧处理；喷火每次对同一角色最多造成一次伤害。

## 场景图提示词
Use case: stylized-concept. Create a production pixel-art background atlas for a side scrolling Chinese fantasy action game. EXACT 2 columns x 2 rows equal cells on a 1536x1024 canvas, no border gutters or text. Each cell is a complete wide background vista. Top left: moonlit mountain monastery with layered blue mountains and a quiet tiled-roof temple off to left. Top right: misty ancient forest and river crossing, enormous curved tree silhouettes at sides, teal fog and distant wooden ferry. Bottom left: ruined underground bell altar, giant ancient bronze bell hanging over distant stairs, muted violet slate, one dim amber light. Bottom right: broken mountain aqueduct and stone bridge over misty ravine, blue grey night. Clean restrained PIXEL ART, large coherent clusters, 8-12 colors per vista, no fine texture or noisy speckles, no outlined boxes, no HUD, no characters, no foreground platforms. Distant architecture, middle of each composition open for readable fighting, lower third dark calm ground mist. Strong simple silhouettes, atmospheric depth. Edges of each quadrant separate cleanly with no padding.

## 环境物件提示词
Use case: stylized-concept. Production game environment sprite atlas, 1536x1024 canvas EXACT 4 columns x 2 rows equal 384x512 cells. Flat solid magenta #ff00ff background for color key, no gradients or shadows outside objects, no text, no gutters. Each object centered with 30px safety margin, bottom aligned at y460 within its cell. Row1: ancient Chinese tiled roof mountain gate with TWO stone pillars and open passage; ruined grey stone arched bridge segment viewed SIDE ON; thick crooked tree trunk with two spreading branches and sparse teal leaf masses; hanging huge old bronze temple bell on simple wooden beam frame. Row2: chunky broken masonry wall with sparse moss; large blue-grey rock cluster with grass tuft; simple wooden walkway side-view with supporting posts and rope rail; squat stone shrine lantern with warm amber flame in open cavity. Crisp restrained PIXEL ART intended to display at 130-250 pixels high, large clusters, 5-8 colors per object, dark desaturated blue stone / brown wood / moss green, sparse ornament, NO gems, NO intricate engraving, NO photographic detail, no fine noise. Distinct clean silhouettes, orthographic sideview assets for platformer.

