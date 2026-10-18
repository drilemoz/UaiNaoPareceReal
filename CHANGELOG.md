# Histórico

## 0.1.0-alpha.3 (17/10/2026)

- Corrigido o único teste falho do workflow #2: fixture HTTP com acentos era codificada implicitamente em Latin-1 e `MetaApi.get()` espera JSON UTF-8.
- Teste agora usa `http.Response.bytes(utf8.encode(...))` com `Content-Type: application/json; charset=utf-8`.
- Acrescentado teste de leitura correta de acentos e emoji mesmo sem indicação explícita de charset, prevenindo regressão.
- Validação estrutural verifica fixture UTF-8 e nomes acentuados.
- No workflow #2: SDK 36 preparado, `flutter analyze` aprovado, 9/10 testes passaram; compilação APK não chegou a executar.
- Versões, notas, tela de novidades, GitHub Manager e nomes de artefatos sincronizados para versionCode 3.
- Sem alterações nas funções da API Meta nem no armazenamento de tokens.

## 0.1.0-alpha.3 (17/10/2026)

- Corrigido workflow 1: ausência de `sdkmanager` no `ubuntu-latest` (exit code 127).
- Adicionado `android-actions/setup-android@v4` e verificação explícita do SDK 36.
- Adicionada validação de regressão da ordem de preparação do Android SDK no CI.
- Sem mudanças em acesso Meta, tela de páginas ou armazenamento de credenciais.
- Compilação APK/Flutter ainda pendente do próximo workflow.

## 0.1.0-alpha.1 (17/10/2026)

- Primeira versão Flutter da central de páginas.
- Tema azul herdando padrões visuais do Uai Vozes v0.26.
- Wizard, novidades, importação SAF, cofre de tokens e Graph API de leitura.
- Dashboard, publicações, reações sob demanda, histórico local e temas.
- Workflow Android 36 para APK debug e release/AAB condicionado a Secrets de assinatura.
