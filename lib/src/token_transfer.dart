import 'dart:convert';
import 'package:flutter/services.dart';

/// Canal SAF inspirado no Uai Vozes v0.26: jamais registrar/exportar o token
/// automaticamente. O arquivo importado não é salvo fora do cofre Android.
class TokenTransfer {
  static const channel = MethodChannel('com.drilemoz.uainaoparecereal/token_transfer');

  static Future<String?> importFromDocument() async {
    final raw = await channel.invokeMethod<String>('importToken');
    return raw == null ? null : parseMetaToken(raw);
  }

  static Future<bool> exportToDocument(String token) async =>
      await channel.invokeMethod<bool>('exportToken', {
        'content': 'META_ACCESS_TOKEN=${token.trim()}\n',
      }) ?? false;
}

String parseMetaToken(String raw) {
  if (raw.length > 8192) throw const FormatException('Arquivo maior que 8 KiB.');
  final content = raw.replaceAll('\ufeff', '').trim();
  if (content.isEmpty) throw const FormatException('Arquivo vazio.');
  String value;
  if (content.startsWith('{')) {
    final object = jsonDecode(content);
    if (object is! Map<String, dynamic>) {
      throw const FormatException('JSON inválido.');
    }
    final item = object['META_ACCESS_TOKEN'] ?? object['FACEBOOK_ACCESS_TOKEN'] ??
        object['PAGE_ACCESS_TOKEN'] ?? object['access_token'];
    if (item is! String) throw const FormatException('JSON sem token.');
    value = item;
  } else {
    final lines = content.split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#') && !line.startsWith('//'))
        .toList();
    if (lines.length != 1) {
      throw const FormatException('Informe apenas um token por arquivo.');
    }
    value = lines.single;
    if (value.startsWith('export ')) value = value.substring(7).trim();
    if (value.contains('=')) {
      final index = value.indexOf('=');
      final key = value.substring(0, index).trim();
      if (!const ['META_ACCESS_TOKEN', 'FACEBOOK_ACCESS_TOKEN',
        'PAGE_ACCESS_TOKEN'].contains(key)) {
        throw const FormatException('Variável inválida para token Meta.');
      }
      value = value.substring(index + 1).trim();
    }
  }
  value = value.trim();
  if (value.length >= 2 && ((value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'")))) {
    value = value.substring(1, value.length - 1);
  }
  if (value.isEmpty || value.length > 4096 || RegExp(r'\s').hasMatch(value) ||
      value.contains('=')) {
    throw const FormatException('Token com formato inválido.');
  }
  return value;
}
