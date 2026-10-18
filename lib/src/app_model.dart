import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'meta_api.dart';

class AppModel extends ChangeNotifier {
  static const version = '0.1.0-alpha.2';
  static const versionCode = 2;
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true));
  final MetaApi api;
  AppModel({MetaApi? metaApi}) : api = metaApi ?? MetaApi();

  SharedPreferences? _prefs;
  ThemeMode themeMode = ThemeMode.system;
  String token = '';
  String pageToken = '';
  String selectedPageId = '';
  MetaPage? selectedPage;
  List<MetaPage> pages = [];
  List<PagePost> posts = [];
  List<Map<String, dynamic>> history = [];
  String lastSeenVersion = '';
  bool loading = false;
  String? error;
  DateTime? updatedAt;
  int _revision = 0;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    try {
      token = await _secure.read(key: 'meta_user_or_page_token') ?? '';
      pageToken = await _secure.read(key: 'meta_selected_page_token') ?? '';
    } catch (_) {
      token = '';
      pageToken = '';
    }
    selectedPageId = _prefs?.getString('selected_page_id') ?? '';
    lastSeenVersion = _prefs?.getString('last_seen_version') ?? '';
    themeMode = switch (_prefs?.getString('theme_mode')) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    try {
      final decoded = jsonDecode(_prefs?.getString('snapshots_v1') ?? '[]');
      history = decoded is List ? decoded.whereType<Map<String, dynamic>>().take(180).toList() : [];
    } catch (_) {
      history = [];
    }
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode next) async {
    themeMode = next;
    notifyListeners();
    await _prefs?.setString('theme_mode', next.name);
  }

  Future<void> acknowledgeVersion() async {
    lastSeenVersion = version;
    await _prefs?.setString('last_seen_version', version);
    notifyListeners();
  }

  Future<void> saveToken(String value) async {
    final safe = value.trim();
    if (safe.isEmpty) throw const FormatException('Token vazio.');
    if (safe != token) {
      // Operações de escrita antes de trocar estado em memória.
      await _secure.write(key: 'meta_user_or_page_token', value: safe);
      await _secure.delete(key: 'meta_selected_page_token');
      await _prefs?.remove('selected_page_id');
      token = safe;
      pageToken = '';
      selectedPageId = '';
      selectedPage = null;
      loading = false;
      pages = [];
      posts = [];
      updatedAt = null;
      error = null;
      _revision++;
      notifyListeners();
    }
  }

  Future<void> removeCredentials() async {
    await _secure.delete(key: 'meta_user_or_page_token');
    await _secure.delete(key: 'meta_selected_page_token');
    await _prefs?.remove('selected_page_id');
    token = '';
    pageToken = '';
    selectedPageId = '';
    selectedPage = null;
    pages = [];
    posts = [];
    loading = false;
    error = null;
    _revision++;
    notifyListeners();
  }

  Future<List<MetaPage>> discoverPages(String candidate) => api.listPages(candidate);

  Future<void> selectPage(MetaPage page) async {
    final credential = page.token ?? token;
    if (credential.isEmpty) throw const FormatException('Sem token autorizado para esta página.');
    await _secure.write(key: 'meta_selected_page_token', value: credential);
    await _prefs?.setString('selected_page_id', page.id);
    pageToken = credential;
    selectedPageId = page.id;
    selectedPage = page;
    loading = false;
    posts = [];
    error = null;
    updatedAt = null;
    _revision++;
    notifyListeners();
  }

  Future<MetaPage> validateDirectPageToken(String candidate) async {
    final value = await api.get('me', candidate,
      query: {'fields':'id,name,category'});
    if (value['category'] is! String || (value['category'] as String).isEmpty) {
      throw const MetaApiException(0, 'Esse token não identificou uma Página. Use um token de Página.');
    }
    return MetaPage.fromJson({...value, 'access_token': candidate});
  }

  Future<void> refresh() async {
    if (loading || selectedPageId.isEmpty || pageToken.isEmpty) return;
    final r = ++_revision;
    final id = selectedPageId;
    final credential = pageToken;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final page = await api.getPage(id, credential);
      final items = await api.getPosts(id, credential);
      if (r != _revision) return;
      selectedPage = page;
      posts = items;
      updatedAt = DateTime.now();
      await _snapshot(page, updatedAt!);
    } catch (e) {
      if (r == _revision) error = e is MetaApiException ? e.message : 'Não foi possível atualizar os dados.';
    } finally {
      if (r == _revision) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _snapshot(MetaPage page, DateTime moment) async {
    if (page.followers == null && page.likes == null) return;
    final day = '${moment.year}-${moment.month.toString().padLeft(2, '0')}-${moment.day.toString().padLeft(2, '0')}';
    history.removeWhere((entry) => entry['date'] == day && entry['page_id'] == page.id);
    history.add({'date': day, 'page_id': page.id, if (page.followers != null) 'followers': page.followers,
      if (page.likes != null) 'likes': page.likes});
    if (history.length > 180) history.removeRange(0, history.length - 180);
    await _prefs?.setString('snapshots_v1', jsonEncode(history));
  }

  List<Map<String, dynamic>> get pageHistory => history.where((entry) =>
    entry['page_id'] == selectedPageId).toList()
    ..sort((a,b) => (a['date'] ?? '').toString().compareTo((b['date'] ?? '').toString()));

  @override
  void dispose() {
    api.dispose();
    super.dispose();
  }
}
