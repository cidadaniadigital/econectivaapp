"""Offline checks for versioned entrypoints; never connects to production."""
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).with_name('deploy-web-release.py')

class ReleasePreparationTest(unittest.TestCase):
    def test_versioned_entrypoints_and_manifest_are_idempotent(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / 'index.html').write_text('<script src="flutter_bootstrap.js" defer></script>')
            (root / 'flutter_bootstrap.js').write_text('{"mainJsPath":"main.dart.js"}\n_flutter.loader.load({serviceWorkerSettings: {serviceWorkerVersion: "123"}});')
            (root / 'main.dart.js').write_text('compiled')
            for relative, size in [('assets/fonts/MaterialIcons-Regular.otf', 1000001), ('assets/packages/cupertino_icons/assets/CupertinoIcons.ttf', 200001)]:
                font = root / relative
                font.parent.mkdir(parents=True, exist_ok=True)
                with font.open('wb') as stream:
                    stream.truncate(size)
            command = ['python3', str(SCRIPT), '--build', str(root), '--revision', 'abcdef1234567', '--prepare-only']
            for _ in range(2):
                result = subprocess.run(command, capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn('flutter_bootstrap.js?atopos_release=abcdef1234567', (root / 'index.html').read_text())
                self.assertIn('main.dart.js?atopos_release=abcdef1234567', (root / 'flutter_bootstrap.js').read_text())
            worker = (root / 'flutter_service_worker.js').read_text()
            self.assertIn('self.skipWaiting()', worker)
            self.assertIn('self.registration.unregister()', worker)
            self.assertNotIn('firebase', worker)
            self.assertNotIn('client.navigate', worker)
            self.assertNotIn('serviceWorkerSettings:', (root / 'flutter_bootstrap.js').read_text())
            self.assertIn('_flutter.loader.load();', (root / 'flutter_bootstrap.js').read_text())
            self.assertEqual(json.loads((root / 'deployment.json').read_text())['commit'], 'abcdef1234567')
            (root / '.env').write_text('protected')
            self.assertNotEqual(subprocess.run(command, capture_output=True).returncode, 0)

if __name__ == '__main__':
    unittest.main()
