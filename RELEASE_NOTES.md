# Uai, Não Parece Real • 0.1.0-alpha.2

Correção de infraestrutura de CI após o workflow 1 falhar na instalação do Android SDK 36 (`sdkmanager: command not found`). Esta versão adiciona `android-actions/setup-android@v4` e valida o SDK antes de gerar APK.

Mantém as funcionalidades da primeira versão: painel de página, publicações, histórico de métricas, importação segura de token e design azul.

**Leitura somente**, sem OAuth público nem postagem automática. Reações pessoais podem ser ocultas pela Meta. Requer token autorizado. Sem métricas artificiais.

**APK Debug:** teste inicial, certificado temporário do runner. **APK release e AAB:** gerados quando há quatro Secrets válidos de assinatura; AAB é o formato apropriado para envio novo ao Google Play.
