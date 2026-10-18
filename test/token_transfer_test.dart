import 'package:flutter_test/flutter_test.dart';
import 'package:uainaoparecereal/src/token_transfer.dart';

void main() {
  test('arquivo .env com token Meta', () {
    expect(parseMetaToken('META_ACCESS_TOKEN=EAA123_abc\n'), 'EAA123_abc');
    expect(parseMetaToken('export META_ACCESS_TOKEN="EAA123"'), 'EAA123');
  });
  test('JSON plano com token', () {
    expect(parseMetaToken('{"access_token":"EAA123"}'), 'EAA123');
  });
  test('token avulso', () {
    expect(parseMetaToken('EAABteste_987'), 'EAABteste_987');
  });
  test('ignora comentário mas recusa múltiplas credenciais', () {
    expect(parseMetaToken('# arquivo privado\nMETA_ACCESS_TOKEN=EAA123'), 'EAA123');
    expect(() => parseMetaToken('META_ACCESS_TOKEN=a\nMETA_ACCESS_TOKEN=b'), throwsFormatException);
    expect(() => parseMetaToken('ELEVENLABS_API_KEY=secreta'), throwsFormatException);
  });
  test('recusa credencial vazia, espaço e tamanho excessivo', () {
    expect(() => parseMetaToken(''), throwsFormatException);
    expect(() => parseMetaToken('META_ACCESS_TOKEN=a b'), throwsFormatException);
    expect(() => parseMetaToken(List.filled(9000, 'a').join()), throwsFormatException);
  });
}
