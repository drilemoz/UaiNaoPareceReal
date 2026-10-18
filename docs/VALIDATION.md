# Validação da alpha.2

Workflow #1: falhou antes da compilação Android, na tarefa **Instalar SDK Android 36**, com `sdkmanager: command not found` (exit code 127). Esta alpha.2 adiciona `android-actions/setup-android@v4` e testa a presença do comando antes da instalação.

Verificações locais possíveis: `python3 tools/validate_source.py`, parser JSON/XML, verificação dos arquivos do código e ZIP.

Não afirmar execução de `flutter analyze`, `flutter test`, Gradle, login Meta, exportação SAF nem APK instalável sem resultados reais do workflow ou testes Android.

O workflow do GitHub Actions executa, nesta ordem: preparação Android, `flutter pub get`, validação estrutural, `flutter analyze`, `flutter test`, APK Debug e, com Secrets, release APK/AAB.

Testes planejados em aparelho: comportamento edge-to-edge API 36; abertura do wizard; autorização Meta; retorno e restrição de nomes de reações; expiração do token; importação/exportação SAF; armazenamento seguro; tema AMOLED; atualização sobre certificado release anterior.
