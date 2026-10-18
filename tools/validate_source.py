#!/usr/bin/env python3
"""Validação local de invariantes (não substitui flutter analyze/build)."""
from pathlib import Path
import json, re, sys, xml.etree.ElementTree as ET
root = Path(__file__).resolve().parents[1]
files = [root / 'pubspec.yaml',root / 'lib/main.dart',root / 'scripts/prepare_android.sh',
         root / '.github/workflows/gerar-apk.yml',root / 'scripts/AndroidManifest.xml']
for file in files:
    assert file.is_file() and file.stat().st_size > 0, f'faltando: {file}'
identity = json.loads((root/'app_identity.json').read_text())
manager = json.loads((root/'github-manager.json').read_text())
assert identity['versionCode'] == manager['versionCode'] == 2
assert identity['versionName'] == manager['versionName'] == '0.1.0-alpha.2'
assert identity['packageName'] == 'com.drilemoz.uainaoparecereal'
assert 'version: 0.1.0-alpha.2+2' in (root/'pubspec.yaml').read_text()
assert 'targetSdk = 36' in (root/'scripts/prepare_android.sh').read_text()
assert 'compileSdk = 36' in (root/'scripts/prepare_android.sh').read_text()
workflow = (root/'.github/workflows/gerar-apk.yml').read_text()
assert workflow.index('uses: android-actions/setup-android@v4') < workflow.index('sdkmanager --install'), 'O SDK precisa ser configurado antes de chamar sdkmanager.'
assert 'command -v sdkmanager' in workflow
assert "sdkmanager --install 'platforms;android-36' 'build-tools;36.0.0'" in workflow
assert 'yes | sdkmanager' not in workflow, 'Nao executar sdkmanager antes de preparar o ambiente'
assert 'flutter build apk --debug' in workflow
assert 'flutter build appbundle --release' in (root/'.github/workflows/gerar-apk.yml').read_text()
assert 'KEYSTORE_BASE64' in (root/'.github/workflows/gerar-apk.yml').read_text()
ET.parse(root/'scripts/AndroidManifest.xml')
assert (root/'scripts/android/MainActivity.kt').read_text().count('token_transfer') == 1
assert "'Authorization': 'Bearer $token'" in (root/'lib/src/meta_api.dart').read_text()
assert "'access_token': token" not in (root/'lib/src/meta_api.dart').read_text()
assert 'ELEVENLABS_API_KEY' not in (root/'lib/src/app_model.dart').read_text()
for f in root.rglob('*'):
    if not f.is_file(): continue
    assert f.suffix not in ('.jks','.keystore','.p12','.env'), f'credencial indevida no fonte: {f}'
print('VALIDAÇÃO ESTRUTURAL: APROVADA (sem compilação Flutter).')
