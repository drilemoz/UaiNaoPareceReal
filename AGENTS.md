# Instruções para evolução

1. Projeto Flutter em pt-BR e tema azul; preservar assistente, novidades, importação SAF, temas claro/AMOLED/sistema e pop-ups.
2. Versionamento sequencial obrigatório, `versionCode` +1 a cada entrega, sincronizar todos os metadados e o nome do APK.
3. Tokens Meta são sensíveis: nunca registrar, enviar para outras origens, imprimir URLs autenticadas, salvar em SharedPreferences nem embutir App Secret no APK.
4. Segurança: API apenas leitura nesta alpha. Pessoas que reagiram só se realmente forem retornadas pela Meta e mediante ação explícita do usuário.
5. Dados ausentes devem permanecer N/D; nunca inventar métricas, históricos, permissões ou rankings.
6. APK Debug obrigatório no CI; APK release e AAB assinados quando os Secrets existirem. Não forçar debug como release para Play.
7. Compilação Flutter e integração Meta reais precisam ser verificadas em GitHub Actions/aparelho; nunca marcá-las como aprovadas sem execução.
8. Para Google Play, usar targetSdk 36 e manter dados de privacidade atualizados; avaliar atualizações futuras do Android/Meta.
