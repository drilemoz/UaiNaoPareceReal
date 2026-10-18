# Uai, Não Parece Real • 0.1.0-alpha.3

Correção do workflow #2, que instalou corretamente o Android SDK 36 e passou na análise estática. O único teste reprovado simulava a resposta da Meta usando codificação Latin-1 para um nome com acento. O mock agora envia JSON UTF-8 em bytes, com teste adicional de Unicode e emoji.

Mantidos o assistente de primeira configuração, importação de tokens, proteção no Android, painel, posts, histórico e consulta opcional de reações. Nenhuma permissão nova foi adicionada.

**Situação:** 9 testes passaram no workflow #2 e um falhou. A correção alpha.3 passou na validação estrutural local, mas ainda requer `flutter test` e geração de APK no GitHub Actions. Acesso real à Meta continua não verificado.
