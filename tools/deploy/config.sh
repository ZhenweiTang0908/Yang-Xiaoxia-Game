# 发布配置（不含密码）。可用同名环境变量临时覆盖。
: "${DEPLOY_DOMAIN:=yang-xiaoxia.newnew-tang.site}"
: "${DEPLOY_SSH_TARGET:=root@47.245.181.53}"
: "${DEPLOY_SSH_KEY:=$HOME/Projects/work_info/keys/frank.pem}"
# 服务器上游戏站点的根目录；releases/ 存每次发布，current 指向正在使用的版本。
: "${DEPLOY_ROOT:=/opt/yang-daxia}"
# 现有 VPN 的 Compose 工程，Nginx 容器在这里。
: "${DEPLOY_VPN_DIR:=/opt/myvpn}"
: "${DEPLOY_KEEP_RELEASES:=3}"
