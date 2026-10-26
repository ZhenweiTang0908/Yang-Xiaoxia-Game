"""Give exported engine and game data independent, content-addressed cache paths."""
import hashlib
import json
from pathlib import Path
import re
import sys


def package(root):
    root = Path(root)
    engine_files = ["index.js", "index.wasm", "index.audio.worklet.js", "index.audio.position.worklet.js"]
    digest = hashlib.sha256()
    for name in engine_files:
        digest.update(name.encode())
        digest.update((root / name).read_bytes())
    engine_dir = "cache/" + digest.hexdigest()[:16]
    pack_dir = "cache/" + hashlib.sha256((root / "index.pck").read_bytes()).hexdigest()[:16]
    for name in engine_files + ["index.pck"]:
        folder = pack_dir if name.endswith(".pck") else engine_dir
        destination = root / folder / name
        destination.parent.mkdir(parents=True, exist_ok=True)
        (root / name).rename(destination)
        (root / name).symlink_to(folder + "/" + name)
    html = (root / "index.html").read_text()
    match = re.search(r"const GODOT_CONFIG = (.*?);", html)
    if not match:
        raise ValueError("Godot export has no configuration")
    config = json.loads(match[1])
    config["executable"] = engine_dir + "/index"
    config["mainPack"] = pack_dir + "/index.pck"
    config["fileSizes"] = {
        pack_dir + "/index.pck": (root / "index.pck").stat().st_size,
        engine_dir + "/index.wasm": (root / "index.wasm").stat().st_size,
    }
    html = html[:match.start(1)] + json.dumps(config, separators=(",", ":")) + html[match.end(1):]
    html = html.replace('src="index.js"', 'src="' + engine_dir + '/index.js"')
    (root / "index.html").write_text(html)
    (root / "web-manifest.json").write_text(json.dumps(config, indent=2) + "\n")
    print("Web cache paths:", engine_dir, pack_dir)


if __name__ == "__main__":
    package(sys.argv[1])
