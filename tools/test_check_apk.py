"""Testes do validador de APK e deteccao de artifact ZIP externo."""
from pathlib import Path
import tempfile
import unittest
from zipfile import ZipFile
from check_apk import check_apk


class ApkCheckTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.path = Path(self.temp.name)

    def fake_apk(self, path):
        with ZipFile(path, 'w') as z:
            z.writestr('AndroidManifest.xml', b'manifest')
            z.writestr('classes.dex', b'dex\n035\0' + b'0' * 512)
            z.writestr('resources.arsc', b'resources')
            z.writestr('assets/flutter_assets/AssetManifest.json', b'{}')

    def test_minimal_apk(self):
        apk = self.path / 'test.apk'
        self.fake_apk(apk)
        self.assertEqual(check_apk(str(apk))['file'], 'test.apk')

    def test_zip_artifact_nao_e_apk(self):
        apk = self.path / 'build.apk'
        self.fake_apk(apk)
        package = self.path / 'artefato.apk'
        with ZipFile(package, 'w') as z:
            z.write(apk, 'build.apk')
        with self.assertRaisesRegex(ValueError, 'Nao e APK Android'):
            check_apk(str(package))

    def test_download_incompleto(self):
        invalid = self.path / 'download.apk'
        invalid.write_bytes(b'PK\x03\x04' + b'0' * 2000)
        with self.assertRaisesRegex(ValueError, 'nao e um ZIP/APK valido'):
            check_apk(str(invalid))

    def test_extensao_errada(self):
        apk = self.path / 'build.zip'
        self.fake_apk(apk)
        with self.assertRaisesRegex(ValueError, 'Extensao invalida'):
            check_apk(str(apk))


if __name__ == '__main__':
    unittest.main()
