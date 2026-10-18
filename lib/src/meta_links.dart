import 'package:url_launcher/url_launcher.dart';

const metaExplorer = 'https://developers.facebook.com/tools/explorer/';
const metaApps = 'https://developers.facebook.com/apps/';
const metaDocs = 'https://developers.facebook.com/docs/pages-api/';

Future<bool> openExternal(String url) async {
  try {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') return false;
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
