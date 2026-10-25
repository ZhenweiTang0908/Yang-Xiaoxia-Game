# 普通攻击声音重做

## 原因与调整

旧版 swing1/2/3 来自按事件序号决定频率的通用合成器，声音由下滑音调与白噪声组成。现在改用挥动物体录音，剪去杂音及多余尾音，做高低频清理、响度整形和淡入淡出。三刀从短促到厚重，每刀三份不同录音，不连续重复同一个变体。没有通过大幅随机变调来制造差异。

命中按肉身、石甲、Boss、盾牌分别处理，每类三种力度、每种三变体；共45条新素材。普通人形的一次近战只发一次主要命中声，群体命中不叠满音量，盾牌格挡不会额外叠肉身声。未命中不会播放命中声。声音依据攻击有效时间启动，挥剑录音的能量峰对齐命中附近；第三刀保留更长的前导和尾部。

4个专用近战声音通道独立于16个普通事件通道；普通命中和消散事件做65ms同类限频。SFX总线增加-1dB上限限制，用户音乐/音效/环境音设置继续生效。

## 试听

声音设置新增「普通攻击试听」，依次播放挥空、肉身、石甲、格挡三连击；再次点击可停止，离开设置停止。试听时音乐平滑降低6dB，结束恢复，不改用户音量设置。

builds/qa/audio/normal-attack-comparison.wav：旧三连命中→新挥空→新肉身命中→新石甲命中，段落之间有停顿。

## 素材来源

- artisticdude, Swishes Sound Pack，CC0：https://opengameart.org/content/swishes-sound-pack 。原作者使用木棒、衣架等录制，原包包含13条挥动声音。
- Kenney, Impact Sounds，CC0：https://kenney.nl/assets/impact-sounds 。使用 punch/soft/mining/wood/metal 素材。

原包及 Kenney License.txt 存在 art_source/audio。完整来源、处理后峰值与RMS见 builds/qa/audio/melee-manifest.json。剪辑脚本 tools/make_melee_audio.py 可重复生成，原通用合成器已避开这些完成编辑的音效。

## 验证边界

tests/melee_audio.gd 7项验证：通道预留、挥空、变体不连重、群体命中合并、格挡分类、第三刀石甲材质及45条资源导入。样本检查无截幅，离线对比混音峰值-4.09dBFS。快速退出仍可能出现Godot资源清理警告；音色是否合意请以试听和实际战斗为准，数值检查不代表主观听感验收。
