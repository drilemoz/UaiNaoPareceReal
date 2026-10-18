# Versionamento

- Versão atual: `0.1.0-alpha.4+4` (`versionCode 4`).
- Incrementar `versionCode` e `alpha.N` em cada atualização; sincronizar `pubspec.yaml`, `app_identity.json`, `github-manager.json`, README, CHANGELOG, RELEASE_NOTES, UI Novidades e nomes do APK e da tag de Release.
- Não publicar Debug como APK assinado de produção. Se o workflow estiver sem Secrets, publicar APK com sufixo `-debug.apk`.
- Nunca assinar builds Release com outra keystore sem procedimento explícito de migração.
