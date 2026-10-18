#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
if ! command -v flutter >/dev/null 2>&1; then
  echo 'Flutter SDK indisponível' >&2; exit 1
fi
if [[ ! -f android/app/build.gradle.kts ]]; then
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  flutter create --no-pub --platforms=android --project-name=uainaoparecereal --org=com.drilemoz "$tmp/uainaoparecereal"
  cp -a "$tmp/uainaoparecereal/android" ./android
fi
mkdir -p android/app/src/main/kotlin/com/drilemoz/uainaoparecereal
cp scripts/AndroidManifest.xml android/app/src/main/AndroidManifest.xml
cp scripts/android/MainActivity.kt android/app/src/main/kotlin/com/drilemoz/uainaoparecereal/MainActivity.kt
# Ícone próprio (não reutilizar o logotipo do Flutter).
for directory in android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}; do
  mkdir -p "$directory"
  cp scripts/assets/icon.png "$directory/ic_launcher.png"
done
python3 - <<'PY'
from pathlib import Path
p=Path('android/app/build.gradle.kts')
s=p.read_text()
# flutter create fornece este arquivo; falhar diante de mudanças inesperadas.
assert 'com.drilemoz.uainaoparecereal' in s, 'Identidade Android inesperada'
assert 'flutter.targetSdkVersion' in s or 'targetSdk = 36' in s, 'Formato Gradle desconhecido'
s=s.replace('targetSdk = flutter.targetSdkVersion','targetSdk = 36')
s=s.replace('compileSdk = flutter.compileSdkVersion','compileSdk = 36')
s=s.replace('minSdk = flutter.minSdkVersion','minSdk = 23')
if 'signingConfigs.getByName("release")' not in s:
    marker='    buildTypes {'
    assert marker in s, 'Bloco buildTypes desconhecido'
    s=s.replace(marker,'''    signingConfigs {
        create("release") {
            storeFile = file("release-key.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD")
            keyAlias = System.getenv("KEY_ALIAS")
            keyPassword = System.getenv("KEY_PASSWORD")
        }
    }
'''+marker,1)
    # Release estável só existe quando o workflow fornece os quatro Secrets.
    # Caso contrário o workflow compila somente DEBUG.
    s=s.replace('signingConfig = signingConfigs.getByName("debug")',
        'signingConfig = signingConfigs.getByName("release")',1)
assert 'targetSdk = 36' in s and 'compileSdk = 36' in s
p.write_text(s)
PY
if [[ -n "${KEYSTORE_BASE64:-}" && -n "${KEYSTORE_PASSWORD:-}" && -n "${KEY_ALIAS:-}" && -n "${KEY_PASSWORD:-}" ]]; then
  umask 077
  printf '%s' "$KEYSTORE_BASE64" | base64 -d > android/app/release-key.jks
  if ! keytool -list -keystore android/app/release-key.jks -storepass:env KEYSTORE_PASSWORD -alias "$KEY_ALIAS" >/dev/null 2>&1; then
    echo 'Secrets de assinatura inválidos' >&2; exit 1
  fi
else
  echo 'Assinatura release não configurada: build Debug de teste permitido.'
fi
