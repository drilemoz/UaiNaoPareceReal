import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_model.dart';
import 'meta_api.dart';
import 'meta_links.dart';
import 'token_transfer.dart';
import 'ui.dart';

class SetupSheet extends StatefulWidget {
  const SetupSheet({super.key, required this.model, this.initialStep = 0});
  final AppModel model;
  final int initialStep;
  @override
  State<SetupSheet> createState() => _SetupSheetState();
}

class _SetupSheetState extends State<SetupSheet> {
  late int step = widget.initialStep;
  late final TextEditingController controller = TextEditingController(text: widget.model.token);
  bool revealed = false;
  bool busy = false;
  String message = '';
  bool isError = false;
  List<MetaPage> found = [];

  @override
  void dispose() { controller.dispose(); super.dispose(); }
  void feedback(String text, {bool error = false}) {
    if (mounted) setState(() { message = text; isError = error; });
  }
  Future<void> paste() async {
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    if (clip?.text != null) setState(() => controller.text = clip!.text!.trim());
  }
  Future<void> importKey() async {
    try {
      final imported = await TokenTransfer.importFromDocument();
      if (mounted && imported != null) {
        setState(() => controller.text = imported);
        feedback('Token importado. Teste e guarde para continuar.');
      }
    } catch (_) { feedback('Arquivo inválido. Use TXT, ENV ou JSON com META_ACCESS_TOKEN.', error:true); }
  }
  Future<void> test() async {
    if (busy) return;
    final candidate = controller.text.trim();
    if (candidate.isEmpty) { feedback('Cole ou importe um token de acesso.', error:true); return; }
    setState(() => busy = true);
    try {
      final pages = await widget.model.discoverPages(candidate);
      if (!mounted) return;
      setState(() => found = pages);
      feedback(pages.isEmpty ? 'Token consultado, mas nenhuma página autorizada foi retornada. Se for token direto de Página, use a opção abaixo.'
        : '${pages.length} página(s) autorizada(s) encontrada(s).');
    } catch (e) { feedback(e is MetaApiException ? e.message : 'Falha de conexão.', error:true); }
    finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> store() async {
    if (busy) return;
    if (controller.text.trim().isEmpty) { feedback('Informe o token primeiro.',error:true); return; }
    setState(() => busy = true);
    try {
      await widget.model.saveToken(controller.text);
      feedback('Token guardado no armazenamento seguro do Android.');
      if (mounted) setState(() => step = 2);
    } catch (_) { feedback('Não foi possível guardar o token.',error:true); }
    finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> choose(MetaPage page) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      if (widget.model.token != controller.text.trim()) {
        await widget.model.saveToken(controller.text);
      }
      await widget.model.selectPage(page);
      if (mounted) Navigator.pop(context);
      await widget.model.refresh();
    } catch (_) { feedback('Não foi possível selecionar a página.', error:true); }
    finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> direct() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final page = await widget.model.validateDirectPageToken(controller.text.trim());
      if (!mounted) return;
      await chooseDirect(page);
    } catch (e) { feedback(e is MetaApiException ? e.message : 'Token de Página inválido.',error:true); }
    finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> chooseDirect(MetaPage page) async {
    await widget.model.saveToken(controller.text);
    await widget.model.selectPage(page);
    if (mounted) Navigator.pop(context);
    await widget.model.refresh();
  }

  @override
  Widget build(BuildContext context) => SafeArea(child: Padding(
    padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
    child: ConstrainedBox(constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .83),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.shield_outlined,color: Theme.of(context).colorScheme.primary), const SizedBox(width: 10),
          Expanded(child: Text('Configurar Meta API',style: Theme.of(context).textTheme.headlineSmall)),
          Text('${step + 1}/3')]),
        const SizedBox(height: 18),
        if (step == 0) ...[
          const Text('Este aplicativo acompanha apenas páginas às quais você tem acesso autorizado.'),
          const SizedBox(height: 12),
          const Text('1. Crie um aplicativo em Meta for Developers. 2. Abra o Graph API Explorer. 3. Gere um token de usuário autorizado com as permissões necessárias. 4. Teste, guarde e escolha sua página.'),
          const SizedBox(height: 12),
          const Text('Permissões comuns: pages_show_list e pages_read_engagement; dados adicionais podem exigir pages_read_user_content e revisão pela Meta.'),
          const SizedBox(height: 16),
          OutlinedButton.icon(onPressed: () => openExternal(metaApps), icon: const Icon(Icons.open_in_new), label: const Text('Criar aplicativo Meta')),
          OutlinedButton.icon(onPressed: () => openExternal(metaExplorer), icon: const Icon(Icons.open_in_new), label: const Text('Abrir Graph API Explorer')),
          const SizedBox(height: 12),
          FilledButton(onPressed: () => setState(() => step = 1), child: const Text('Continuar')),
        ] else ...[
          Text('Token de acesso',style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          TextField(controller: controller, obscureText: !revealed,
            autocorrect: false, enableSuggestions: false,
            decoration: InputDecoration(hintText:'EAAB...',labelText:'Meta Access Token',
            suffixIcon: IconButton(tooltip: 'Mostrar ou ocultar',
              icon: Icon(revealed ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => revealed = !revealed)))),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            TextButton.icon(onPressed: busy ? null : paste, icon: const Icon(Icons.content_paste),label: const Text('Colar')),
            TextButton.icon(onPressed: busy ? null : importKey, icon: const Icon(Icons.file_open),label: const Text('Importar')),
            TextButton.icon(onPressed: busy ? null : test, icon: const Icon(Icons.wifi_tethering),label: const Text('Testar')),
            TextButton.icon(onPressed: busy ? null : store, icon: const Icon(Icons.lock_outline),label: const Text('Guardar')),
            TextButton.icon(onPressed: () => openExternal(metaExplorer), icon: const Icon(Icons.open_in_new),label: const Text('Obter token')),
          ]),
          const SizedBox(height: 9),
          const Text('Tokens podem expirar. Não use App Secret dentro do APK. Importação aceita TXT, ENV ou JSON. ', style: TextStyle(fontSize: 12)),
          if (busy) const LinearProgressIndicator(),
          if (message.isNotEmpty) ...[const SizedBox(height: 10), InlineFeedback(message: message,isError:isError)],
          if (step == 2) ...[
            const SectionTitle('Selecionar página'),
            if (found.isEmpty) TextButton.icon(onPressed: busy ? null : test,
              icon: const Icon(Icons.refresh), label: const Text('Consultar páginas disponíveis')),
            for (final page in found)
              Card(child: ListTile(title: Text(page.name),subtitle: Text('ID: ${page.id}'),
                trailing: const Icon(Icons.arrow_forward_ios), onTap: busy ? null : () => choose(page))),
            OutlinedButton.icon(onPressed: busy ? null : direct,
              icon: const Icon(Icons.link), label: const Text('Conectar token direto de Página')),
            const Text('Se a Meta não mostrar sua página, verifique funções administrativas, permissões e expiração do token.',
              style: TextStyle(fontSize: 12)),
          ] else ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: busy ? null : store, child: const Text('Guardar e selecionar página')),
          ],
        ],
      ]))),
  ));
}

Future<void> showSetup(BuildContext context, AppModel model) =>
  showModalBottomSheet<void>(context: context, isScrollControlled:true,
    useSafeArea:true, showDragHandle:true, backgroundColor:Theme.of(context).colorScheme.surface,
    builder: (_) => SetupSheet(model:model,initialStep:model.token.isEmpty ? 0 : 2));
