import 'dart:async';
import 'package:flutter/material.dart';
import 'src/app_model.dart';
import 'src/onboarding.dart';
import 'src/pages.dart';
import 'src/ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final model = AppModel();
  await model.load();
  runApp(UaiApp(model:model));
}

class UaiApp extends StatelessWidget {
  const UaiApp({super.key,required this.model});
  final AppModel model;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation:model,builder:(ctx,_) => MaterialApp(
    title:'Uai, Não Parece Real',debugShowCheckedModeBanner:false,
    theme:uaiNaoPareceRealTheme(Brightness.light),
    darkTheme:uaiNaoPareceRealTheme(Brightness.dark),
    themeMode:model.themeMode,locale:const Locale('pt','BR'),
    home:MainShell(model:model),
  ));
}

class MainShell extends StatefulWidget {
  const MainShell({super.key,required this.model});
  final AppModel model;
  @override
  State<MainShell> createState() => _MainShellState();
}
class _MainShellState extends State<MainShell> {
  int tab = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) unawaited(initial()); });
  }
  Future<void> initial() async {
    if (widget.model.lastSeenVersion != AppModel.version) await showChanges();
    if (!mounted) return;
    if (widget.model.selectedPageId.isEmpty || widget.model.pageToken.isEmpty) {
      await showSetup(context,widget.model);
    } else {
      unawaited(widget.model.refresh());
    }
  }
  Future<void> showChanges() async {
    await showModalBottomSheet<void>(context:context,showDragHandle:true,
      backgroundColor:Theme.of(context).colorScheme.surface,builder:(ctx) => SafeArea(
      child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,
        crossAxisAlignment:CrossAxisAlignment.start,children:[
        Icon(Icons.auto_awesome,color:Theme.of(ctx).colorScheme.primary,size:36),
        const SizedBox(height:12),Text('Novidades • alpha.1',style:Theme.of(ctx).textTheme.headlineSmall),
        const SizedBox(height:13),
        const Text('• Tema azul, aparência AMOLED e painel organizado.\n'
          '• Configuração orientada da Meta API, importação, teste e armazenamento seguro do token.\n'
          '• Páginas autorizadas, publicações, reações retornadas e histórico local.\n'
          '• Consulta opcional de pessoas que reagiram, quando a Meta disponibilizar.\n'
          '• Preparação para APK e pacote Google Play pelo GitHub Actions.'),
        const SizedBox(height:22),SizedBox(width:double.infinity,child:FilledButton(
          onPressed:() => Navigator.pop(ctx),child:const Text('Entendi'))),
      ]))));
    await widget.model.acknowledgeVersion();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    body:IndexedStack(index:tab,children:[
      HomePage(model:widget.model,openPosts:() => setState(() => tab=1)),
      PostsPage(model:widget.model),
      HistoryPage(model:widget.model),
      SettingsPage(model:widget.model,showChanges:showChanges),
    ]),
    bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(index) => setState(() => tab=index),
      destinations:const [
        NavigationDestination(icon:Icon(Icons.space_dashboard_outlined),selectedIcon:Icon(Icons.space_dashboard),label:'Painel'),
        NavigationDestination(icon:Icon(Icons.slow_motion_video_outlined),selectedIcon:Icon(Icons.slow_motion_video),label:'Posts'),
        NavigationDestination(icon:Icon(Icons.timeline_outlined),selectedIcon:Icon(Icons.timeline),label:'Histórico'),
        NavigationDestination(icon:Icon(Icons.tune_outlined),selectedIcon:Icon(Icons.tune),label:'Ajustes'),
      ]),
  );
}
