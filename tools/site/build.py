"""Assemble the landing page and its local media, without exporting or deploying."""
import argparse
import html
import json
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "tools/site"
MEDIA = ROOT / "builds/site-media"
MEDIA_FILES = ("intro.mp4", "intro-poster.jpg", "intro.zh.vtt")


def assemble(site, metadata, mac_size, win_size):
    missing = [str(MEDIA / name) for name in MEDIA_FILES if not (MEDIA / name).is_file()]
    if missing:
        raise SystemExit("缺少首页视频素材，请先放入 builds/site-media/：\n" + "\n".join(missing))
    page = (SOURCE / "index.html").read_text()
    for key, value in {"MAC_SIZE": mac_size, "WIN_SIZE": win_size}.items():
        page = page.replace("{{" + key + "}}", html.escape(value))
    for key, field in {"HAS_WEB": "web", "HAS_MAC": "macos", "HAS_WIN": "windows"}.items():
        page = page.replace("{{" + key + "}}", json.dumps(bool(metadata[field])))
    if "{{" in page:
        raise SystemExit("首页仍有未填入的构建占位符")
    (site / "media").mkdir(parents=True, exist_ok=True)
    for name in MEDIA_FILES:
        shutil.copy2(MEDIA / name, site / "media" / name)
    shutil.copy2(SOURCE / "site.css", site / "site.css")
    (site / "index.html").write_text(page)
    metadata["intro"] = True
    (site / "version.json").write_text(json.dumps(metadata, ensure_ascii=False) + "\n")
    print(f"首页与介绍视频已组装：{site}（未部署）")


def package_size(file):
    return f"{file.stat().st_size / 1024 / 1024:.0f} MB"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--refresh", action="store_true", help="Only refresh an existing local release site")
    parser.add_argument("site", type=Path)
    parser.add_argument("build_args", nargs="*")
    args = parser.parse_args()
    if args.refresh:
        if args.build_args:
            parser.error("--refresh does not take export metadata")
        version_file = args.site / "version.json"
        if not version_file.is_file():
            raise SystemExit("还没有本地发布站点，请先运行 tools/release.sh build")
        metadata = json.loads(version_file.read_text())
        mac_size = win_size = ""
        for key, filename in (("macos", "YangDaxia-macOS.zip"), ("windows", "YangDaxia-Windows.zip")):
            package = args.site / "downloads" / filename
            if metadata[key] and not package.is_file():
                raise SystemExit(f"下载包缺失：{package}")
            if metadata[key]:
                if key == "macos":
                    mac_size = package_size(package)
                else:
                    win_size = package_size(package)
        if metadata["web"] and not (args.site / "play/index.html").is_file():
            raise SystemExit("本地网页版缺失，请先运行 tools/release.sh build")
    else:
        if len(args.build_args) != 5:
            parser.error("expected version, built_at, has_web, mac_size, win_size")
        version, built_at, has_web, mac_size, win_size = args.build_args
        metadata = {"version": version, "built_at": built_at, "web": has_web == "1", "macos": bool(mac_size), "windows": bool(win_size)}
    assemble(args.site, metadata, mac_size, win_size)


if __name__ == "__main__":
    main()
