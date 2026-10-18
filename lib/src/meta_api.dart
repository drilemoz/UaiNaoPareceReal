import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// API somente leitura. O corpo de erro remoto pode conter dados sensíveis;
/// não é exposto na interface, persistência, erros ou registros.
class MetaApiException implements Exception {
  final int status;
  final String message;
  const MetaApiException(this.status, this.message);
  @override
  String toString() => message;
}

class MetaPage {
  final String id;
  final String name;
  final String? token;
  final int? followers;
  final int? likes;
  const MetaPage({required this.id, required this.name, this.token,
    this.followers, this.likes});

  factory MetaPage.fromJson(Map<String, dynamic> value) => MetaPage(
    id: (value['id'] ?? '').toString(),
    name: (value['name'] ?? 'Página sem nome').toString(),
    token: value['access_token'] is String ? value['access_token'] as String : null,
    followers: asCount(value['followers_count']),
    likes: asCount(value['fan_count']),
  );
}

int? asCount(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}

int? summaryCount(dynamic object) {
  if (object is! Map) return null;
  final summary = object['summary'];
  return summary is Map ? asCount(summary['total_count']) : null;
}

class PagePost {
  final String id;
  final String message;
  final DateTime? created;
  final Uri? url;
  final int? reactions;
  final int? comments;
  final int? shares;
  const PagePost({required this.id, required this.message, this.created,
    this.url, this.reactions, this.comments, this.shares});

  factory PagePost.fromJson(Map<String, dynamic> raw) {
    Uri? link;
    final v = raw['permalink_url'];
    if (v is String) {
      final parsed = Uri.tryParse(v);
      if (parsed != null && parsed.scheme == 'https') link = parsed;
    }
    return PagePost(
      id: (raw['id'] ?? '').toString(),
      message: (raw['message'] ?? '').toString(),
      created: DateTime.tryParse((raw['created_time'] ?? '').toString()),
      url: link,
      reactions: summaryCount(raw['reactions']),
      comments: summaryCount(raw['comments']),
      shares: raw['shares'] is Map ? asCount((raw['shares'] as Map)['count']) : null,
    );
  }
}

class MetaReaction {
  final String? name;
  final String type;
  const MetaReaction(this.name, this.type);
  factory MetaReaction.fromJson(Map<String, dynamic> json) => MetaReaction(
    json['name'] is String ? json['name'] as String : null,
    (json['type'] ?? 'REAÇÃO').toString(),
  );
}

class MetaApi {
  MetaApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const version = 'v26.0';
  static final _base = Uri.parse('https://graph.facebook.com/$version/');

  Future<Map<String, dynamic>> get(String path, String token,
      {Map<String, String> query = const {}}) async {
    if (token.trim().isEmpty) throw const MetaApiException(0, 'Token não informado.');
    // Somente caminhos internos conhecidos, nunca permitir URL de terceiros.
    if (!RegExp(r'^[a-zA-Z0-9_./-]+$').hasMatch(path) || path.contains('..') || path.startsWith('/')) {
      throw const MetaApiException(0, 'Caminho inválido.');
    }
    final uri = _base.resolve(path).replace(queryParameters: query);
    http.Response response;
    try {
      response = await _client.get(uri, headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 18));
    } on TimeoutException {
      throw const MetaApiException(0, 'Tempo de resposta esgotado.');
    } on SocketException {
      throw const MetaApiException(0, 'Sem conexão de rede.');
    } on http.ClientException {
      throw const MetaApiException(0, 'Falha de conexão.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final code = response.statusCode;
      throw MetaApiException(code, switch (code) {
        400 => 'Consulta recusada. Confira as permissões e os campos disponíveis.',
        401 || 403 => 'Acesso negado. Confira permissões ou validade do token.',
        429 => 'Limite de consultas atingido. Tente mais tarde.',
        >= 500 => 'Serviço da Meta indisponível. Tente novamente.',
        _ => 'Falha HTTP $code ao consultar a Meta.',
      });
    }
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Objeto JSON esperado.');
      }
      return decoded;
    } on FormatException {
      throw const MetaApiException(0, 'A Meta retornou dados inesperados.');
    }
  }

  Future<List<MetaPage>> listPages(String userToken) async {
    final result = await get('me/accounts', userToken,
      query: {'fields':'id,name,access_token', 'limit':'100'});
    final rows = result['data'];
    if (rows is! List) throw const MetaApiException(0, 'Resposta de páginas inválida.');
    return rows.whereType<Map<String, dynamic>>().map(MetaPage.fromJson)
        .where((p) => p.id.isNotEmpty).toList();
  }

  Future<MetaPage> getPage(String id, String token) async {
    // Propriedades extras podem não existir em algumas páginas/versões;
    // fallback sem números, em vez de inventar métricas.
    try {
      return MetaPage.fromJson(await get(id, token,
        query: {'fields': 'id,name,followers_count,fan_count'}));
    } on MetaApiException catch (e) {
      if (e.status != 400) rethrow;
      return MetaPage.fromJson(await get(id, token, query: {'fields':'id,name'}));
    }
  }

  Future<List<PagePost>> getPosts(String id, String token) async {
    const core = 'id,message,created_time,permalink_url';
    const extras = '$core,shares,comments.limit(0).summary(true),reactions.limit(0).summary(true)';
    Map<String, dynamic> payload;
    try {
      payload = await get('$id/posts', token, query: {'fields': extras, 'limit':'30'});
    } on MetaApiException catch (e) {
      if (e.status != 400) rethrow;
      payload = await get('$id/posts', token, query: {'fields': core, 'limit':'30'});
    }
    final rows = payload['data'];
    if (rows is! List) throw const MetaApiException(0, 'Resposta de publicações inválida.');
    return rows.whereType<Map<String, dynamic>>().map(PagePost.fromJson)
        .where((p) => p.id.isNotEmpty).toList();
  }

  /// Opcional e sob demanda. A Meta pode devolver só contagens, anonimizar
  /// resultados ou negar pessoas individuais. Nenhum nome é fabricado.
  Future<List<MetaReaction>> getPeopleWhoReacted(String postId, String token) async {
    final result = await get('$postId/reactions', token,
        query: {'fields': 'name,type', 'limit': '25'});
    final rows = result['data'];
    if (rows is! List) throw const MetaApiException(0, 'Resposta de reações inválida.');
    return rows.whereType<Map<String, dynamic>>().map(MetaReaction.fromJson).toList();
  }

  void dispose() => _client.close();
}
