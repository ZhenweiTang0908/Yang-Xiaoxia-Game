# 角色图鉴

双击 `tools/open_boss_catalog.command` 打开本地图鉴。页面只在本机 `127.0.0.1:8769` 提供静态文件，不连接外网。

角色列表与技能摘要维护在 `data.js`；图片和语音直接引用项目 `assets/`。数值以当前 `data/bosses/`、`scripts/core/balance.gd` 和角色战斗脚本中的基础参数为准。游戏调整后，同步更新图鉴数据。
