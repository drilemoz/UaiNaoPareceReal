# Uai, Não Parece Real

**0.1.0-alpha.4** | Flutter | Android | idioma pt-BR

Aplicativo independente para acompanhar uma página autorizada do Facebook pela Meta Graph API, com visual azul inspirado no **Uai Vozes v0.26**. Não é afiliado ao Facebook nem à Meta.

## Funcionalidades da alpha.4

**Alpha.4:** ajuste de distribuição após o erro `DOWNLOAD_CONTENT_INVALID` no GitHub Manager. A compilação produz um APK, enquanto os Artifacts de Actions são entregues como ZIP. Agora o APK direto é anexado ao GitHub Releases e recebe validação interna antes de ser publicado.

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

## Correção alpha.4: APK direto, não ZIP

- O GitHub Actions encapsula sempre os arquivos enviados por `actions/upload-artifact` em um ZIP.
- O GitHub Manager pode rejeitar esse ZIP como se fosse APK: `DOWNLOAD_CONTENT_INVALID`.
- Agora, após a compilação, o workflow verifica o APK internamente e publica o **APK real como arquivo separado em GitHub Releases**, automaticamente.
- Sem Secrets: Release de pré-lançamento contém **`-debug.apk`**, só para instalar e testar. Com os quatro Secrets de assinatura: contém **`-release.apk`** e **`.aab`**.
- Abra a aba **Releases** no GitHub Manager, não a opção de download dos **Artifacts** do Actions. Se um download antigo falhou, remova-o antes de baixar o APK pelo Release.
- Uma falha `DOWNLOAD_CONTENT_INVALID` **não prova falha de compilação**. Confirme se o workflow inteiro concluiu com sucesso.

## Primeira configuração

1. Crie seu app em https://developers.facebook.com/apps/
2. Abra https://developers.facebook.com/tools/explorer/
3. Selecione seu app Meta, gere token de usuário para sua página, observando `pages_show_list`, `pages_read_engagement` e outras permissões quando necessárias.
4. Cole ou importe o token no aplicativo; toque em **Testar**, **Guardar** e escolha a página.
5. Se já possuir **token de Página**, tente **Conectar token direto de Página**.

**Atenção:** Graph API Explorer é recomendado para testes próprios. Tokens podem expirar e podem precisar de permissões/revisão App Review. Não embuta App Secret em apps móveis. A alpha.4 não implementa OAuth de produção, publicação nem monitoramento em segundo plano.

## Gerar APK no GitHub Actions

1. Envie **o conteúdo do projeto** (não o ZIP da fonte) à raiz do repositório, incluindo `.github`.
2. Em **Actions > Gerar APK Uai Nao Parece Real**, inicie a execução ou faça push na branch principal.
3. O workflow executa `flutter analyze`, `flutter test`, compila, valida a estrutura do APK e publica uma **Release de pré-lançamento**, com `.apk` direto.
4. Em **Releases > v0.1.0-alpha.4 > Assets**, baixe **o arquivo que termina em `.apk`**. NÃO utilize arquivos `.zip` dos Artifacts como APK.
5. Se não houver os Secrets, o asset será `-debug.apk`, válido para testes mas **não apropriado para Google Play**. Com KEYSTORE_BASE64, KEYSTORE_PASSWORD, KEY_ALIAS e KEY_PASSWORD, gera APK de produção assinado e AAB.
6. GitHub Actions deve possuir permissão `contents: write`; as regras de proteção do repositório também podem limitar criação de tags e Releases.

**Nota:** o aplicativo GitHub Manager precisará selecionar a fonte **GitHub Releases** para baixar o `.apk` diretamente. Esse projeto não altera o código do próprio GitHub Manager.

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
