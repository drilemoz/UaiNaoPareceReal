# Rascunho técnico de privacidade para revisão (não é política publicada)

Este app é um cliente independente da API oficial Meta Graph. Ao conectar, o usuário fornece um token. O token fica no armazenamento criptografado do Android via plugin flutter_secure_storage. A API recebe o token em cabeçalho HTTPS Authorization: Bearer; não há backend próprio nesta alpha.

Dados locais incluem identificador da página selecionada, contagens retornadas e snapshots de métricas. Publicações não são persistidas intencionalmente nesta versão. Não há rastreadores, anúncios nem telemetria de terceiros incluídos pelo projeto (o comportamento de SDKs/dependências deve ser revisto antes de publicar).

A exportação de token é ação explícita e avisa sobre sensibilidade. O app não acessa livremente arquivos, usando SAF apenas quando selecionado.

Antes de publicar no Google Play: criar política pública adaptada ao uso real, cumprir requisitos de exclusão de dados e formulário Data safety, validar a revisão Meta (se aplicável), verificar permissões e dependências finais.
