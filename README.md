# Uai, Não Parece Real

**0.1.0-alpha.3** | Flutter | Android | idioma pt-BR

Aplicativo independente para acompanhar uma página autorizada do Facebook pela Meta Graph API, com visual azul inspirado no **Uai Vozes v0.26**. Não é afiliado ao Facebook nem à Meta.

## Funcionalidades da alpha.3

**Correção do workflow 2:** o Android SDK 36 já foi instalado, `flutter analyze` aprovou sem problemas e 9/10 testes passaram. A falha era um teste que construía resposta HTTP acentuada com bytes Latin-1, enquanto a API corretamente interpreta JSON UTF-8. A alpha.3 corrige o mock com `http.Response.bytes(utf8.encode(...))` e adiciona teste de Unicode sem charset. A geração do APK ainda depende do próximo workflow.

- Primeira abertura: **Novidades** e **assistente de configuração** com passos guiados.
- Ações para colar, importar, testar, guardar e obter token, usando Graph API Explorer.
- Importa `.txt`, `.env` e JSON plano pela seleção nativa de arquivos do Android. Pode exportar token com confirmação explícita.
- Token de usuário e token da página guardados em `flutter_secure_storage` (Android); não são incluídos em logs.
- Páginas autorizadas via `GET /me/accounts`, seleção e consulta da página.
- Dashboard de seguidores/curtidas, quando a API permitir, sem números de demonstração.
- Últimas 30 publicações, comparação por reações/comentários, abrir post no Facebook.
- Consulta manual e opcional das pessoas que reagiram. A Meta pode **não revelar nomes** ou negar completamente a consulta.
- Histórico de snapshots **locais** por dia, apenas quando a API retorna dados.
- Temas claro, preto AMOLED e sistema; navegação inferior e pop-ups personalizados.

## Primeira configuração

1. Crie seu app em https://developers.facebook.com/apps/
2. Abra https://developers.facebook.com/tools/explorer/
3. Selecione seu app Meta, gere token de usuário para sua página, observando `pages_show_list`, `pages_read_engagement` e outras permissões quando necessárias.
4. Cole ou importe o token no aplicativo; toque em **Testar**, **Guardar** e escolha a página.
5. Se já possuir **token de Página**, tente **Conectar token direto de Página**.

**Atenção:** Graph API Explorer é recomendado para testes próprios. Tokens podem expirar e podem precisar de permissões/revisão App Review. Não embuta App Secret em apps móveis. A alpha.3 não implementa OAuth de produção, publicação nem monitoramento em segundo plano.

## Gerar APK no GitHub Actions

1. Crie um repositório e envie o conteúdo deste projeto à raiz, mantendo a pasta `.github`.
2. Em **Actions > Gerar APK Uai Nao Parece Real > Run workflow**, execute o workflow.
3. Mesmo sem Secrets, o workflow valida, roda testes e compila **APK Debug ARM64 de teste**. O Android gerado e o APK não estão dentro do ZIP de código-fonte.
4. O GitHub Actions distribui seus **Artifacts** em uma embalagem ZIP padrão da plataforma. O arquivo dentro é um `.apk` real.
5. Para APK **release estável** e AAB Google Play, configure os 4 GitHub Secrets `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS` e `KEY_PASSWORD`. O workflow gera `.apk` e `.aab` assinados e pode anexá-los **diretamente** ao GitHub Releases (sem ZIP), pela tag `v0.1.0-alpha.3` ou entrada `publicar_release`.

**Não compartilhe keystore privada** e não use o certificado debug para futuras atualizações. Não altere o `applicationId` depois de publicar.

## Google Play

- `applicationId`: `com.drilemoz.uainaoparecereal`.
- `targetSdk 36`, `compileSdk 36`, `minSdk 23`.
- AAB de release assinado disponível no workflow quando Secrets estiverem presentes.
- Pendências antes da publicação: **teste real, análise de segurança, política de privacidade, formulário Data safety, material visual e fluxo OAuth/App Review da Meta quando exigido**. Esta entrega não comprova aprovação pela Play Store.

## Limitações reconhecidas

- Facebook restringe identidades pessoais de quem reagiu; **não prometer nomes**.
- Algumas métricas podem retornar `N/D`, inclusive em páginas pequenas ou sem permissões.
- Histórico só registra dados observados; não faz medição contínua ou retroativa.
- Paginação de posts limitada a 30 registros por sincronização nesta alpha.
- Não foi executado um teste real com credencial Meta, que deve ser fornecida pelo titular.

## Desenvolvimento

```bash
flutter pub get
bash scripts/prepare_android.sh
flutter analyze
flutter test
flutter build apk --debug --target-platform android-arm64
```

Para release: definir os quatro Secrets antes de `prepare_android.sh` e durante `flutter build apk --release` / `flutter build appbundle --release`.
