# Uai, Não Parece Real • 0.1.0-alpha.4

**Correção do download de APK no GitHub Manager.** O workflow antigo publicava o APK como artifact do GitHub Actions, que é servido pela API dentro de um ZIP. O Gerenciador identificou o download como APK e apresentou `DOWNLOAD_CONTENT_INVALID`.

Esta versão cria uma **Release de pré-lançamento com o arquivo APK direto**, após validar AndroidManifest.xml, classes.dex e resources.arsc dentro do APK. Sem Secrets de assinatura publica um APK `-debug.apk` para testes; com Secrets completos publica APK Release assinado e AAB para Google Play.

Para instalar pelo GitHub Manager, escolha **GitHub Releases > Assets > arquivo .apk**. Não renomeie ZIP de Actions para APK.

Visual azul, onboarding, configuração Meta, posts, histórico e privacidade foram mantidos. Flutter/Android e download real de Releases ainda precisam ser verificados pelo próximo workflow e aparelho.
