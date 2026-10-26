#!/bin/bash
# 在服务器上执行（由 tools/release.sh deploy 通过 ssh 管道调用）。
# 把游戏站点接入现有 VPN 工程里的 Nginx 容器，可重复执行：已完成的步骤会跳过。
#   1. compose.yaml 给 nginx 加一个只读挂载：$ROOT -> /srv/yang-daxia
#   2. nginx.conf 的 http 块末尾加一行 include 站点配置
#   3. 用 certbot --expand 把 $DOMAIN 加进现有证书
# 改 compose.yaml / nginx.conf 前先备份；新配置先在临时容器里 nginx -t，失败就恢复备份。
set -euo pipefail
: "${DOMAIN:?}" "${ROOT:?}" "${VPN_DIR:?}"

MOUNT=/srv/yang-daxia
SITE_CONF="$ROOT/nginx/site.conf"
INCLUDE_LINE="  include $MOUNT/nginx/site.conf;"
COMPOSE="$VPN_DIR/compose.yaml"
NGINX_CONF="$VPN_DIR/data/nginx/nginx.conf"
LIVE="$VPN_DIR/certbot/conf/live"
BACKUP_DIR=/opt/myvpn-backups

cd "$VPN_DIR"
dc() { docker compose --env-file env "$@"; }
log() { echo "  [server] $*"; }

[[ -f "$COMPOSE" && -f "$NGINX_CONF" ]] || { echo "找不到 $COMPOSE 或 $NGINX_CONF" >&2; exit 1; }
mkdir -p "$ROOT/releases" "$ROOT/nginx"

# 现有证书只有一张（vpn 域名那张），游戏域名加进同一张，沿用已有的自动续期和重载。
cert_name="$(ls -1 "$LIVE" | grep -v README | head -n1)"
[[ -n "$cert_name" ]] || { echo "找不到现有证书" >&2; exit 1; }
cert_has_domain() {
  openssl x509 -in "$LIVE/$cert_name/fullchain.pem" -noout -ext subjectAltName | grep -q "DNS:$DOMAIN\b"
}

write_site_conf() {
  # $1 = http | full。证书签下来之前只放 80 端口的验证路径。
  local tmp; tmp="$(mktemp)"
  cat > "$tmp" <<EOF
# 由 Yang-Daxia 的 tools/deploy/server_setup.sh 生成，请勿手改；重新部署会覆盖。
server {
  listen 80;
  server_name $DOMAIN;

  location /.well-known/acme-challenge/ {
    root /var/www/certbot;
  }

  location / {
    return 301 https://\$host\$request_uri;
  }
}
EOF
  if [[ "$1" == full ]]; then
    cat >> "$tmp" <<EOF

server {
  listen 443 ssl http2;
  server_name $DOMAIN;

  ssl_certificate /etc/letsencrypt/live/$cert_name/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/$cert_name/privkey.pem;
  ssl_protocols TLSv1.2 TLSv1.3;

  # 头部只写在 server 级：location 里一旦写 add_header，这里的就全部失效。
  add_header Strict-Transport-Security "max-age=31536000" always;
  add_header X-Content-Type-Options nosniff always;
  add_header Referrer-Policy no-referrer always;
  # HTML and stable aliases revalidate; content-addressed assets can be reused.
  set \$game_cache_control "no-cache";
  add_header Cache-Control \$game_cache_control always;

  access_log /var/log/nginx/yang-daxia.access.log;

  include /etc/nginx/mime.types;
  default_type application/octet-stream;

  # index.wasm / index.pck / index.js 在发布时已预压缩为 .gz。
  gzip_static on;
  gzip_vary on;
  gzip on;
  gzip_types text/css application/javascript application/json image/svg+xml;

  root $MOUNT/current;
  index index.html;

  # Only content-addressed resources are immutable; HTML always revalidates.
  location ~ "^/play/cache/[a-f0-9]{16}/" {
    set \$game_cache_control "public, max-age=31536000, immutable";
    try_files \$uri =404;
  }

  location / {
    try_files \$uri \$uri/ =404;
  }
}
EOF
  fi
  if ! cmp -s "$tmp" "$SITE_CONF"; then
    # 原地写入，保证容器里看到的是同一个文件。
    cat "$tmp" > "$SITE_CONF"
    rm -f "$tmp"
    return 0
  fi
  rm -f "$tmp"
  return 1
}

compose_ready() { grep -q "$ROOT:$MOUNT:ro" "$COMPOSE"; }
nginx_conf_ready() { grep -qF "$INCLUDE_LINE" "$NGINX_CONF"; }
container_has_mount() {
  docker inspect "$(dc ps -q nginx)" --format '{{range .Mounts}}{{.Source}} {{end}}' | grep -qw "$ROOT"
}

# 解析检查：域名必须已经指向本机，否则证书签不下来。
public_ip="$(curl -4 -s -m 5 http://100.100.100.200/latest/meta-data/eipv4 || true)"
[[ -n "$public_ip" ]] || public_ip="$(curl -4 -s -m 5 https://api.ipify.org || true)"
resolved="$(getent ahostsv4 "$DOMAIN" | awk 'NR==1{print $1}')"
if [[ -n "$public_ip" && "$resolved" != "$public_ip" ]]; then
  echo "$DOMAIN 解析到 '${resolved:-无}'，本机公网 IP 是 $public_ip，请先确认 DNS" >&2
  exit 1
fi

# ---- 第 1、2 步：compose 挂载和 include ----
if cert_has_domain; then phase=full; else phase=http; fi
site_changed=0
write_site_conf "$phase" && site_changed=1

if ! compose_ready || ! nginx_conf_ready || ! container_has_mount; then
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  backup="$BACKUP_DIR/yang-daxia-setup-$stamp.tar.gz"
  mkdir -p "$BACKUP_DIR"
  tar -czf "$backup" -C "$VPN_DIR" compose.yaml data/nginx/nginx.conf
  log "已备份 compose.yaml 和 nginx.conf 到 $backup"
  restore() {
    log "恢复备份 $backup"
    # 原地写回 nginx.conf，单文件挂载才能继续生效。
    tar -xzf "$backup" -C "$VPN_DIR" compose.yaml
    tar -xzOf "$backup" data/nginx/nginx.conf > "$NGINX_CONF"
  }

  python3 - "$COMPOSE" "$NGINX_CONF" "$ROOT" "$MOUNT" "$INCLUDE_LINE" <<'EOF'
import sys, re
compose, nginx_conf, root, mount, include_line = sys.argv[1:]
text = open(compose).read()
volume = f"{root}:{mount}:ro"
if volume not in text:
    anchor = re.search(r"^(\s*)- \./data/logs/nginx:/var/log/nginx\s*$", text, re.M)
    if not anchor:
        sys.exit("compose.yaml 里找不到 nginx 日志挂载行，无法安全插入")
    line = f"\n{anchor.group(1)}- {volume}"
    text = text[:anchor.end()] + line + text[anchor.end():]
    with open(compose, "r+") as f:
        f.seek(0); f.write(text); f.truncate()
conf = open(nginx_conf).read()
if include_line not in conf:
    end = conf.rstrip().rfind("}")
    if end < 0:
        sys.exit("nginx.conf 结构不符合预期")
    conf = conf[:end] + "\n" + include_line + "\n" + conf[end:]
    with open(nginx_conf, "r+") as f:
        f.seek(0); f.write(conf); f.truncate()
EOF

  if ! dc config --quiet; then restore; echo "compose.yaml 校验失败，已恢复" >&2; exit 1; fi

  # 在临时容器里用新配置跑 nginx -t，不影响正在运行的 Nginx。
  network="$(docker inspect "$(dc ps -q nginx)" --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}' | awk '{print $1}')"
  if ! docker run --rm --network "$network" \
      -v "$NGINX_CONF:/etc/nginx/nginx.conf:ro" \
      -v "$VPN_DIR/certbot/www:/var/www/certbot:ro" \
      -v "$VPN_DIR/certbot/conf:/etc/letsencrypt:ro" \
      -v "$ROOT:$MOUNT:ro" \
      nginx:1.28-alpine nginx -t; then
    restore; echo "新 Nginx 配置测试失败，已恢复" >&2; exit 1
  fi

  log "重建 nginx 容器（订阅页会中断几秒，Hysteria 不受影响）"
  dc up -d --no-deps nginx
  sleep 2
  if ! dc exec -T nginx nginx -t; then
    restore; dc up -d --no-deps nginx
    echo "重建后 nginx -t 失败，已恢复原配置" >&2; exit 1
  fi
  site_changed=0
elif (( site_changed )); then
  dc exec -T nginx nginx -t
  dc exec -T nginx nginx -s reload
  log "站点配置已更新并重载"
fi

# ---- 第 3 步：证书 ----
if ! cert_has_domain; then
  # 先确认 80 端口的验证路径已经指向 certbot 目录。
  probe="yang-daxia-probe-$RANDOM"
  mkdir -p "$VPN_DIR/certbot/www/.well-known/acme-challenge"
  echo ok > "$VPN_DIR/certbot/www/.well-known/acme-challenge/$probe"
  got="$(curl -s -m 5 --resolve "$DOMAIN:80:127.0.0.1" "http://$DOMAIN/.well-known/acme-challenge/$probe" || true)"
  rm -f "$VPN_DIR/certbot/www/.well-known/acme-challenge/$probe"
  [[ "$got" == ok ]] || { echo "验证路径不通，未申请证书" >&2; exit 1; }

  domains="$(openssl x509 -in "$LIVE/$cert_name/fullchain.pem" -noout -ext subjectAltName \
    | grep -o 'DNS:[^, ]*' | sed 's/DNS:/-d /' | tr '\n' ' ')"
  log "扩展证书 $cert_name：$domains -d $DOMAIN"
  # shellcheck disable=SC2086
  dc --profile tools run --rm certbot certonly --webroot --webroot-path /var/www/certbot \
    --cert-name "$cert_name" $domains -d "$DOMAIN" --expand --non-interactive --keep-until-expiring
  cert_has_domain || { echo "证书扩展后仍不含 $DOMAIN" >&2; exit 1; }

  write_site_conf full || true
  dc exec -T nginx nginx -t
  dc exec -T nginx nginx -s reload
  log "证书已包含 $DOMAIN，HTTPS 站点已启用"
fi

# The lossy overseas path collapses CUBIC's congestion window. Keep BBR scoped
# to the web container; host TCP defaults and the UDP VPN remain unchanged.
if [[ "$(docker inspect "$(dc ps -q nginx)" --format '{{index .HostConfig.Sysctls "net.ipv4.tcp_congestion_control"}}')" != bbr ]]; then
  modprobe tcp_bbr
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  mkdir -p "$BACKUP_DIR"
  tcp_backup="$BACKUP_DIR/yang-daxia-nginx-tcp-$stamp.yaml"
  cp "$COMPOSE" "$tcp_backup"
  python3 - "$COMPOSE" <<'PYCODE'
import re, sys
path = sys.argv[1]
text = open(path).read()
match = re.search(r"(?ms)^  nginx:\n.*?(?=^  [a-zA-Z_-]+:|\Z)", text)
if not match:
    sys.exit("Cannot locate nginx service")
section = match[0]
if "    sysctls:" in section:
    sys.exit("Unexpected nginx sysctls; preserve existing settings for review")
section = section.replace("    ports:\n", "    sysctls:\n      net.ipv4.tcp_congestion_control: bbr\n    ports:\n", 1)
if "net.ipv4.tcp_congestion_control: bbr" not in section:
    sys.exit("Cannot locate nginx ports")
with open(path, "w") as f:
    f.write(text[:match.start()] + section + text[match.end():])
PYCODE
  if ! dc config --quiet || ! dc up -d --no-deps nginx || ! dc exec -T nginx nginx -t; then
    cp "$tcp_backup" "$COMPOSE"
    dc up -d --no-deps nginx
    echo "Nginx BBR 配置失败，已恢复 $tcp_backup" >&2
    exit 1
  fi
  printf '%s\n' tcp_bbr > /etc/modules-load.d/yang-daxia-bbr.conf
  log "Web 容器已启用 BBR；原配置备份：$tcp_backup"
fi

log "服务器配置就绪"
