# Validação da alpha.4

## Evidência da captura do GitHub Manager

- Aviso `DOWNLOAD_CONTENT_INVALID`: arquivo baixado não tem estrutura mínima de APK.
- Workflow alpha.3 armazenava APK por `actions/upload-artifact@v4`, cujo download da API do GitHub é um ZIP externo.
- A captura sozinha não prova que o build da alpha.3 falhou; é preciso conferir a conclusão do workflow e o tipo de download.

## Mudanças na alpha.4

- Retirado o upload de artifacts que induzia download ZIP rotulado como APK.
- Release direta passa a ser publicada automaticamente após build e testes bem-sucedidos, mesmo sem assinatura de produção.
- `-debug.apk` quando não há Secrets; `-release.apk` e `.aab` somente com os quatro Secrets de assinatura.
- `tools/check_apk.py` valida magic ZIP, estrutura interna de APK e rejeita ZIP de artifact que apenas contém outro APK.
- Testes de `check_apk` para APK mínimo, inválido, e arquivo ZIP externo.
- Versionamento sequencial alpha.4+4.

## Validações locais

Executar `python3 tools/validate_source.py`, `python3 -m unittest discover -s tools -p 'test_*.py'`, parser JSON/XML, `bash -n`, YAML e integridade CRC do ZIP.

**Pendências:** executar o workflow alpha.4; teste `flutter analyze`, `flutter test`, build Debug e assinatura Release em GitHub Actions; verificar a presença de APK direto em Assets de Releases; instalar no Android. Não presumir aprovação pelo Google Play.
