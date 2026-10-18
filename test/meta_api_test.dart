import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uainaoparecereal/src/meta_api.dart';

void main() {
  test('envia bearer via cabeçalho, não via URL', () async {
    final api = MetaApi(client: MockClient((request) async {
      expect(request.url.toString(), contains('/v26.0/me/accounts'));
      expect(request.url.queryParameters.containsKey('access_token'),isFalse);
      expect(request.headers['Authorization'],'Bearer TOKEN-SUPER-PRIVADO');
      return http.Response(jsonEncode({'data':[{'id':'123','name':'Página Teste','access_token':'PAGINA-TOKEN'}]}),200);
    }));
    final pages = await api.listPages('TOKEN-SUPER-PRIVADO');
    expect(pages.length,1);
    expect(pages.single.token,'PAGINA-TOKEN');
    api.dispose();
  });
  test('métricas presentes e ausentes não geram valores fictícios', () {
    final rich = PagePost.fromJson({
      'id':'123_456','message':'Olá','reactions':{'summary':{'total_count':31}},
      'comments':{'summary':{'total_count':2}},'shares':{'count':4},
    });
    expect(rich.reactions,31);
    expect(rich.comments,2);
    expect(rich.shares,4);
    final sparse = PagePost.fromJson({'id':'123','message':'Texto'});
    expect(sparse.reactions,isNull);
    expect(sparse.comments,isNull);
    expect(sparse.shares,isNull);
  });
  test('nunca inclui corpo remoto em erro HTTP', () async {
    const sensitive = 'TOKEN_SENSIVEL_NO_CORPO';
    final api = MetaApi(client:MockClient((_) async => http.Response(sensitive,400)));
    try {
      await api.get('me/accounts','TOKEN');
      fail('esperava erro');
    } on MetaApiException catch (error) {
      expect(error.toString(),isNot(contains(sensitive)));
      expect(error.status,400);
    }
    api.dispose();
  });
  test('consulta reações apenas campos autorizados, sem inventar nomes', () async {
    final api = MetaApi(client: MockClient((request) async {
      expect(request.url.path, '/v26.0/1_2/reactions');
      return http.Response('{"data":[{"type":"LIKE"}]}',200);
    }));
    final people = await api.getPeopleWhoReacted('1_2','PAGE_TOKEN');
    expect(people.single.name,isNull);
    api.dispose();
  });
  test('recusa caminho arbitrário para outro servidor', () async {
    final api = MetaApi(client: MockClient((_) async => http.Response('{}',200)));
    expect(() => api.get('https://attacker.invalid','TOKEN'),throwsA(isA<MetaApiException>()));
    api.dispose();
  });
}
