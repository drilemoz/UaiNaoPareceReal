# Histórico

## 0.1.0-alpha.2 (17/10/2026)

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
