# 原图上半身与补画下半身

内置 image_gen 编辑 assets/art/hero_2d/hero/00.png，生成候选 art_source/run-studies/unarmed-candidate.png。此图没有直接替换角色：实验 tests/hero_rebuilt_gait.gd 仅取下半身，头脸、衣领、上衣、手与剑使用原有 00.png 的纹理。所有合成通过 Godot 网格和 UV 完成，原 PNG 未改写。

最终生成提示：

> Precise-object-edit. Edit this exact sprite with ONE change: remove the entire sword from the boy's hand, and reconstruct the charcoal shorts and legs that were hidden behind the blade. Keep his hand empty in the same position. Preserve exact face, head, hair, neck, collar, shirt with bear, body proportions, standing pose, bare feet, colors, pixel texture and silhouette. Do not redesign, enlarge the head, smooth pixels, add lighting, add shadows or change proportions. Full body centered on a genuinely transparent alpha background. No checkerboard pixels, no background gradient. We need the original sprite without the sword for 2D skeletal animation.

alpha 检查：1339×1175，1249107 像素 alpha 小于 .01，54159 半透明像素。为实验排除边缘噪点，绘制网格只覆盖 alpha 至少 .7 的原纹理像素。候选上衣残片从腿层排除；髋部用低对比底色填补接缝。

0.56 秒循环，半周期贴地后移，半周期前摆抬脚。大腿、小腿刚性旋转，两段关节求解；脚掌独立保持朝向。rebuilt_gait_validation.gd 的 240 次腿部采样中，关节连接无误，支撑脚底垂直误差为 0。该检查不证明地面水平方向无滑步，也不证明美术合格。

实际样片 builds/qa/rebuilt-gait.mp4：下半身不再有原剑遮挡造成的缺块，白色衣摆碎片已排除。但短裤转动形状偏硬，手臂和武器仍固定站姿，没有完整跑步的身体配合。尚需髋部遮挡与裤腿轮廓调整、摆臂、起跑停止和跳落衔接。没有接入正式游戏，本轮无需重新导出。

后续裤腿变形：将顶部 y≤145 的裤腰顶点完全绑定躯干，145–167 之间逐渐跟随大腿，下缘保持大腿变换。避免裤腰随腿整体翻转。录制已更新。当前试验每次绘制重建两块裤腿网格，正式接入前仍需处理更新成本。

rebuilt_stride_audit.gd 验证 240 个采样：裤腰绑定误差 0，按该步幅对应的原图坐标速度 71.4286 像素/秒计算，支撑期间单帧世界位置漂移最大 0.0000073。此速度绝不是当前游戏 225 像素/秒，且还需乘角色缩放系数；不能据此声称正式跑步不滑。当前只构成低速步态，真正跑步需要更大步幅、较短支撑阶段和腾空阶段，并匹配游戏移动速度，不能单纯把整段动画加速。
