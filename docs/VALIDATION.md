# Validação da alpha.3

## Evidência do workflow #2 (18/10/2026 UTC)

- `sdkmanager` e SDK Android 36: concluídos.
- `flutter pub get`: concluído.
- `python3 tools/validate_source.py`: APROVADO.
- `flutter analyze`: **No issues found!** (6,4 segundos).
- `flutter test`: **9 aprovados, 1 falhou**, em `test/meta_api_test.dart` > `envia bearer via cabeçalho, não via URL`.
- Mensagem do teste falho: `A Meta retornou dados inesperados.`; origem `MetaApi.get` ao decodificar bytes. O mock `http.Response(String, 200)` usava Latin-1 sem charset, mas continha `Página Teste` com acento. JSON da API usa UTF-8. Correção no mock, não no decoder seguro da API.
- O APK não foi compilado no workflow #2 porque `flutter test` encerrou o job com exit code 1.

## Alterações alpha.3

- Fixture usa bytes UTF-8 explicitamente. Aserção verifica nome `Página Teste`.
- Teste adicional garante acentos e emoji em JSON UTF-8 sem charset.
- `tools/validate_source.py` assegura que fixture UTF-8 permanece presente.

## Validações locais alpha.3

Executar `python3 tools/validate_source.py`, parser JSON/XML, Bash `-n`, YAML e verificação CRC do ZIP. Ausência de Flutter/Dart no ambiente impede rodar `flutter test`, `flutter analyze` e Gradle localmente.

**Pendências:** executar o workflow da alpha.3; testar importação SAF, login Meta, falhas de token, comportamento API 36 e APK em Android físico. Não presumir aprovação Google Play.
