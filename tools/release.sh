#!/bin/zsh
# 编译与发布。build 只在本地生成 dist/site，不碰服务器；deploy 才上传到服务器。
#   tools/release.sh build [web|macos|windows ...]   默认三端全编
#   tools/release.sh deploy                          上传 dist/site 并切换到新版本
#   tools/release.sh status                          查看服务器上的版本
#   tools/release.sh rollback                        切回上一个版本
set -eu
cd "${0:A:h:h}"
source tools/deploy/config.sh

site=dist/site
export_timeout=900

ssh_run() {
  ssh -i "$DEPLOY_SSH_KEY" -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=10 \
    -o ForwardAgent=no "$DEPLOY_SSH_TARGET" "$@"
}

human_size() { du -h "$1" | cut -f1 | tr -d ' '; }

export_target() {
  # Godot 出错时可能不退出，导出一律加硬超时。
  if ! timeout -k 10 "$export_timeout" tools/build.sh "$1"; then
    echo "导出 $1 失败或超时" >&2
    exit 1
  fi
}

cmd_build() {
  local targets=("$@")
  (( ${#targets} )) || targets=(web macos windows)
  for t in $targets; do
    case "$t" in web|macos|windows) ;; *) echo "未知目标：$t（可选 web macos windows）" >&2; exit 2 ;; esac
  done

  local version stamp
  version="$(git describe --always --dirty 2>/dev/null || echo nogit)"
  stamp="$(date '+%Y-%m-%d %H:%M')"

  for t in $targets; do
    echo "== 导出 $t"
    export_target "$t"
  done

  echo "== 组装 $site"
  rm -rf "$site"
  mkdir -p "$site/play" "$site/downloads"

  # 只有本次导出的目标才进站点；没编的平台在页面上显示为暂不可用。
  local mac_size="" win_size="" has_web=0
  if (( ${targets[(Ie)web]} )); then
    has_web=1
    cp builds/web/index.{html,js,wasm,pck,png} builds/web/index.audio.worklet.js \
      builds/web/index.audio.position.worklet.js "$site/play/"
    # 预压缩大文件，Nginx 用 gzip_static 直接发送。
    gzip -9 -k "$site/play/index.wasm" "$site/play/index.pck" "$site/play/index.js"
  fi
  if (( ${targets[(Ie)macos]} )); then
    cp builds/macos/YangDaxia.zip "$site/downloads/YangDaxia-macOS.zip"
    mac_size="$(human_size "$site/downloads/YangDaxia-macOS.zip")"
  fi
  if (( ${targets[(Ie)windows]} )); then
    rm -f "$site/downloads/YangDaxia-Windows.zip"
    (cd builds/windows && zip -q -9 "../../$site/downloads/YangDaxia-Windows.zip" YangDaxia.exe)
    win_size="$(human_size "$site/downloads/YangDaxia-Windows.zip")"
  fi

  sips -s format jpeg -s formatOptions 82 assets/art/moon_shrine.png --out "$site/bg.jpg" >/dev/null
  python3 - "$site" "$version" "$stamp" "$has_web" "$mac_size" "$win_size" <<'EOF'
import sys, json, pathlib
site, version, stamp, has_web, mac, win = sys.argv[1:]
page = pathlib.Path('tools/site/index.html').read_text()
for key, value in {'VERSION': version, 'BUILT_AT': stamp, 'MAC_SIZE': mac, 'WIN_SIZE': win}.items():
    page = page.replace('{{' + key + '}}', value)
page = page.replace('{{HAS_WEB}}', 'true' if has_web == '1' else 'false')
page = page.replace('{{HAS_MAC}}', 'true' if mac else 'false')
page = page.replace('{{HAS_WIN}}', 'true' if win else 'false')
pathlib.Path(site, 'index.html').write_text(page)
pathlib.Path(site, 'version.json').write_text(json.dumps(
    {'version': version, 'built_at': stamp, 'web': has_web == '1', 'macos': bool(mac), 'windows': bool(win)},
    ensure_ascii=False) + '\n')
EOF

  echo
  echo "编译完成（未部署）：版本 $version"
  du -sh "$site" "$site"/play "$site"/downloads/* 2>/dev/null
  echo "本地预览：python3 -m http.server -d $site 8766，然后打开 http://127.0.0.1:8766"
}

cmd_deploy() {
  [[ -f "$site/version.json" ]] || { echo "没有 $site，请先运行 tools/release.sh build" >&2; exit 1; }
  local release
  release="$(date -u '+%Y%m%dT%H%M%SZ')"

  echo "== 检查服务器一次性配置（Nginx 站点与证书）"
  # 先把脚本放到服务器上再执行：用 bash -s 从标准输入喂脚本时，脚本里的 docker compose exec
  # 会把标准输入（也就是脚本剩下的部分）读走，后面的步骤就悄悄不执行了。
  ssh_run "mkdir -p '$DEPLOY_ROOT' && cat > '$DEPLOY_ROOT/server_setup.sh'" < tools/deploy/server_setup.sh
  ssh_run "DOMAIN='$DEPLOY_DOMAIN' ROOT='$DEPLOY_ROOT' VPN_DIR='$DEPLOY_VPN_DIR' bash '$DEPLOY_ROOT/server_setup.sh'" < /dev/null

  echo "== 上传版本 $release"
  ssh_run "mkdir -p '$DEPLOY_ROOT/releases/$release'"
  local link_dest=()
  local previous
  previous="$(ssh_run "readlink '$DEPLOY_ROOT/current' 2>/dev/null || true")"
  [[ -n "$previous" ]] && link_dest=(--link-dest="$DEPLOY_ROOT/$previous")
  # macOS 自带的 openrsync 不支持 --info，用 --progress；--link-dest 让没变的文件直接硬链接，不重复上传。
  rsync -a --delete --progress "${link_dest[@]}" \
    -e "ssh -i $DEPLOY_SSH_KEY -o IdentitiesOnly=yes -o BatchMode=yes -o ForwardAgent=no" \
    "$site/" "$DEPLOY_SSH_TARGET:$DEPLOY_ROOT/releases/$release/"

  echo "== 切换到新版本并清理旧版本"
  ssh_run "set -e; cd '$DEPLOY_ROOT'; chmod -R a+rX releases/$release
    ln -sfn releases/$release current.tmp && mv -Tf current.tmp current
    ls -1d releases/*/ | sort | head -n -$DEPLOY_KEEP_RELEASES | xargs -r rm -rf"

  verify_site
  echo "部署完成：https://$DEPLOY_DOMAIN/"
}

verify_site() {
  echo "== 线上验证"
  local base="https://$DEPLOY_DOMAIN" failed=0
  check() {
    local label="$1" expect="$2"; shift 2
    local got
    got="$(curl --noproxy '*' -sS -m 20 -o /dev/null "$@" 2>&1 || true)"
    if [[ "$got" == $~expect ]]; then echo "  ok   $label：$got"; else echo "  FAIL $label：$got（期望 $expect）"; failed=1; fi
  }
  check "落地页" "200" -w '%{http_code}' "$base/"
  check "版本号" "200" -w '%{http_code}' "$base/version.json"
  if curl --noproxy '*' -sS -m 20 "$base/version.json" | grep -q '"web": true'; then
    check "游戏页" "200" -w '%{http_code}' "$base/play/"
    check "wasm 类型" "200 application/wasm" -w '%{http_code} %{content_type}' -I "$base/play/index.wasm"
    check "wasm 压缩" "*gzip*" -w '%header{content-encoding}' -H 'Accept-Encoding: gzip' -I "$base/play/index.wasm"
  fi
  for f in YangDaxia-macOS.zip YangDaxia-Windows.zip; do
    [[ -f "$site/downloads/$f" ]] && check "下载 $f" "200" -w '%{http_code}' -I "$base/downloads/$f"
  done
  # 确认 VPN 相关站点没被影响。
  source <(ssh_run "grep -E '^(SUB_DOMAIN|VPN_DOMAIN)=' '$DEPLOY_VPN_DIR/env'")
  check "VPN 订阅站 $SUB_DOMAIN" "[2-5][0-9][0-9]" -w '%{http_code}' "https://$SUB_DOMAIN/"
  check "VPN 域名 $VPN_DOMAIN" "404" -w '%{http_code}' "https://$VPN_DOMAIN/"
  (( failed == 0 )) || { echo "有检查未通过，可用 tools/release.sh rollback 切回上一版" >&2; return 1; }
}

cmd_status() {
  ssh_run "cd '$DEPLOY_ROOT' 2>/dev/null || { echo '服务器上还没有部署过'; exit 0; }
    echo \"当前：\$(readlink current)\"; cat current/version.json 2>/dev/null; echo '已保留版本：'; ls -1 releases"
}

cmd_rollback() {
  ssh_run "set -e; cd '$DEPLOY_ROOT'
    cur=\$(readlink current); prev=\$(ls -1d releases/*/ | sed 's#/\$##' | sort | grep -B1 -x \"\$cur\" | head -n1)
    [ -n \"\$prev\" ] && [ \"\$prev\" != \"\$cur\" ] || { echo '没有更早的版本可回滚'; exit 1; }
    ln -sfn \"\$prev\" current.tmp && mv -Tf current.tmp current; echo \"已切回 \$prev\""
}

case "${1:-}" in
  build) shift; cmd_build "$@" ;;
  deploy) cmd_deploy ;;
  status) cmd_status ;;
  rollback) cmd_rollback ;;
  *) echo "用法：tools/release.sh build [web|macos|windows ...] | deploy | status | rollback" >&2; exit 2 ;;
esac
