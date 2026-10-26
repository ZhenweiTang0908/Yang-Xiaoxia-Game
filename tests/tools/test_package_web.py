import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("package_web", Path(__file__).resolve().parents[2] / "tools/package_web.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class WebPackagingTest(unittest.TestCase):
    def build(self, root, pack):
        for name in ["index.js", "index.wasm", "index.audio.worklet.js", "index.audio.position.worklet.js"]:
            (root / name).write_bytes(name.encode())
        (root / "index.pck").write_bytes(pack)
        (root / "index.html").write_text('<script src="index.js"></script>\nconst GODOT_CONFIG = {"executable":"index","fileSizes":{}};')
        module.package(root)
        return json.loads((root / "web-manifest.json").read_text())

    def test_cache_urls_match_real_exported_bytes_and_keep_compatibility_aliases(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            config = self.build(root, b"game-data")
            for name, size in config["fileSizes"].items():
                self.assertEqual((root / name).stat().st_size, size)
            self.assertEqual((root / config["mainPack"]).read_bytes(), b"game-data")
            self.assertEqual((root / "index.pck").read_bytes(), b"game-data")
            self.assertIn('src="' + config["executable"] + '.js"', (root / "index.html").read_text())
            self.assertTrue((root / (config["executable"] + ".audio.worklet.js")).is_file())

    def test_game_update_invalidates_pack_but_reuses_unchanged_engine(self):
        with tempfile.TemporaryDirectory() as a, tempfile.TemporaryDirectory() as b:
            first = self.build(Path(a), b"before")
            second = self.build(Path(b), b"after")
            self.assertEqual(first["executable"], second["executable"])
            self.assertNotEqual(first["mainPack"], second["mainPack"])


if __name__ == "__main__":
    unittest.main()
