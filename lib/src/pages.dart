import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_model.dart';
import 'meta_api.dart';
import 'meta_links.dart';
import 'onboarding.dart';
import 'token_transfer.dart';
import 'ui.dart';

String formatCount(int? count) {
  if (count == null) return 'N/D';
  if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)} mi';
  if (count >= 10000) return '${(count / 1000).toStringAsFixed(1)} mil';
  return count.toString();
}
String showDate(DateTime? date) {
  if (date == null) return 'Data indisponível';
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2,'0')}/${local.month.toString().padLeft(2,'0')}/${local.year}  ${local.hour.toString().padLeft(2,'0')}:${local.minute.toString().padLeft(2,'0')}';
}

class HomePage extends StatelessWidget {
  const HomePage({super.key,required this.model,required this.openPosts});
  final AppModel model;
  final VoidCallback openPosts;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation:model, builder:(context, _) {
    final page = model.selectedPage;
    final scored = model.posts.where((post) => post.reactions != null).toList()
      ..sort((a,b) => (b.reactions ?? 0).compareTo(a.reactions ?? 0));
    return RefreshIndicator(onRefresh:model.refresh, child: CustomScrollView(physics:const AlwaysScrollableScrollPhysics(),slivers:[
      SliverAppBar(title: const Text('Uai, Não Parece Real'),floating:true,
        actions:[IconButton(tooltip:'Atualizar',onPressed:model.loading ? null : model.refresh,
          icon:const Icon(Icons.refresh_rounded))]),
      SliverPadding(padding: const EdgeInsets.all(16), sliver: SliverList(delegate:SliverChildListDelegate([
        if (page == null) ...[
          const SizedBox(height: 90),
          EmptyState(icon:Icons.dashboard_customize_outlined,title:'Sua página em um só lugar',
            description:'Conecte a Meta API para ver dados reais da sua página, publicações e histórico. Não há valores de demonstração.',
            action:FilledButton.icon(onPressed:() => showSetup(context,model),
              icon:const Icon(Icons.link),label:const Text('Configurar conexão'))),
        ] else ...[
          UaiCard(child:Row(children:[
            CircleAvatar(radius:26,child:Text(page.name.isNotEmpty ? page.name.substring(0,1).toUpperCase() : 'P')),
            const SizedBox(width:12),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
              Text(page.name,style:Theme.of(context).textTheme.titleLarge),
              Text('Página conectada • ${model.updatedAt == null ? 'sem atualização' : showDate(model.updatedAt)}',
                style:Theme.of(context).textTheme.bodySmall),
            ])),
            IconButton(tooltip:'Trocar página',onPressed:() => showSetup(context,model),icon:const Icon(Icons.swap_horiz_rounded)),
          ])),
          const SectionTitle('Resumo da página'),
          Row(children:[
            Expanded(child:_stat(context,Icons.people_alt_outlined,'Seguidores',formatCount(page.followers))),
            const SizedBox(width:10),
            Expanded(child:_stat(context,Icons.thumb_up_alt_outlined,'Curtidas da página',formatCount(page.likes))),
          ]),
          const SizedBox(height:10),
          Row(children:[
            Expanded(child:_stat(context,Icons.article_outlined,'Posts consultados','${model.posts.length}')),
            const SizedBox(width:10),
            Expanded(child:_stat(context,Icons.favorite_border,'Reações nos posts',
              _reactionsTotal(model.posts))),
          ]),
          const SizedBox(height:8),
          Text('Reações somadas apenas nos posts retornados com contagens. Não representam o alcance total da página.',
            style:Theme.of(context).textTheme.bodySmall),
          const SectionTitle('Destaques recentes'),
          if (scored.isEmpty)
            const UaiCard(child:Text('Sem contagens disponíveis para classificar publicações.'))
          else for (final post in scored.take(3)) ...[
            PostTile(post:post,model:model,compact:true), const SizedBox(height:9),
          ],
          const SizedBox(height:8),
          OutlinedButton.icon(onPressed:openPosts,icon:const Icon(Icons.list_alt_rounded),
            label:const Text('Ver todas as publicações')),
          if (model.error != null) ...[
            const SizedBox(height:14),InlineFeedback(message:model.error!,isError:true)],
          if (model.loading) const Padding(padding:EdgeInsets.only(top:20),child:LinearProgressIndicator()),
        ],
        const SizedBox(height:90),
      ]))),
    ]));
  });

  String _reactionsTotal(List<PagePost> posts) {
    final values = posts.where((e) => e.reactions != null).toList();
    if (values.isEmpty) return 'N/D';
    return formatCount(values.fold<int>(0,(total,p) => total + p.reactions!));
  }
  Widget _stat(BuildContext context,IconData icon,String label,String value) => UaiCard(
    padding:const EdgeInsets.all(14), child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Icon(icon,color:Theme.of(context).colorScheme.primary,size:22),
      const SizedBox(height:13),Text(value,style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.bold)),
      const SizedBox(height:3),Text(label,maxLines:2,style:Theme.of(context).textTheme.labelSmall),
    ]));
}

class PostsPage extends StatefulWidget {
  const PostsPage({super.key,required this.model});
  final AppModel model;
  @override
  State<PostsPage> createState() => _PostsPageState();
}
class _PostsPageState extends State<PostsPage> {
  String filter = 'recentes';
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation:widget.model,builder:(context,_) {
    final selected = widget.model.selectedPage != null;
    final list = [...widget.model.posts];
    if (filter == 'reacoes') {
      list.sort((a,b) => (b.reactions ?? -1).compareTo(a.reactions ?? -1));
    } else if (filter == 'comentarios') {
      list.sort((a,b) => (b.comments ?? -1).compareTo(a.comments ?? -1));
    }
    return Scaffold(appBar:AppBar(title:const Text('Publicações'),actions:[
      IconButton(onPressed: widget.model.loading ? null : widget.model.refresh,
        icon:const Icon(Icons.sync_rounded),tooltip:'Atualizar')]),
      body: !selected ? EmptyState(icon:Icons.article_outlined,title:'Sem página selecionada',
        description:'Configure a Meta API para consultar suas publicações.',
        action:FilledButton(onPressed:() => showSetup(context,widget.model),child:const Text('Configurar')))
        : RefreshIndicator(onRefresh:widget.model.refresh,child:ListView(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.all(16),children:[
          Wrap(spacing:7,children:[
            ChoiceChip(label:const Text('Recentes'),selected:filter=='recentes',onSelected:(_) => setState(() => filter='recentes')),
            ChoiceChip(label:const Text('Mais reações'),selected:filter=='reacoes',onSelected:(_) => setState(() => filter='reacoes')),
            ChoiceChip(label:const Text('Mais comentários'),selected:filter=='comentarios',onSelected:(_) => setState(() => filter='comentarios')),
          ]),
          const SizedBox(height:8),
          Text('Últimas ${list.length} publicações disponibilizadas pela API. Métricas ausentes aparecem como N/D.',style:Theme.of(context).textTheme.bodySmall),
          if (widget.model.error != null) ...[const SizedBox(height:9),InlineFeedback(message:widget.model.error!,isError:true)],
          if (widget.model.loading) const LinearProgressIndicator(),
          if (list.isEmpty && !widget.model.loading) const Padding(padding:EdgeInsets.only(top:60),child:EmptyState(
            icon:Icons.hourglass_empty,title:'Nenhuma publicação retornada',
            description:'Verifique permissões e toque em Atualizar.')),
          for (final post in list) ...[const SizedBox(height:10),PostTile(post:post,model:widget.model)],
          const SizedBox(height:80),
        ])),
    );
  });
}

class PostTile extends StatelessWidget {
  const PostTile({super.key,required this.post,required this.model,this.compact=false});
  final PagePost post;
  final AppModel model;
  final bool compact;
  @override
  Widget build(BuildContext context) => UaiCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(showDate(post.created),style:Theme.of(context).textTheme.bodySmall),
    const SizedBox(height:9),
    Text(post.message.isEmpty ? 'Publicação sem texto (foto, vídeo ou link)' : post.message,
      maxLines:compact ? 2 : 5,overflow:TextOverflow.ellipsis,style:Theme.of(context).textTheme.bodyMedium),
    const SizedBox(height:12),
    Wrap(spacing:15,runSpacing:9,children:[
      _metric(Icons.favorite_border,'${formatCount(post.reactions)} reações'),
      _metric(Icons.chat_bubble_outline,'${formatCount(post.comments)} comentários'),
      _metric(Icons.share_outlined,'${formatCount(post.shares)} compartilhamentos'),
    ]),
    if (!compact) ...[
      const SizedBox(height:10), const Divider(),
      Wrap(spacing:8,children:[
        TextButton.icon(onPressed:() => showPeople(context,post,model),
          icon:const Icon(Icons.people_outline),label:const Text('Quem reagiu?')),
        if (post.url != null) TextButton.icon(onPressed:() => openExternal(post.url.toString()),
          icon:const Icon(Icons.open_in_new),label:const Text('Abrir no Facebook')),
      ]),
    ],
  ]));
  Widget _metric(IconData icon,String label) => Row(mainAxisSize:MainAxisSize.min,
    children:[Icon(icon,size:16),const SizedBox(width:4),Text(label,style:const TextStyle(fontSize:12))]);
}

Future<void> showPeople(BuildContext context, PagePost post,AppModel model) async {
  await showModalBottomSheet<void>(context:context,isScrollControlled:true,showDragHandle:true,
    backgroundColor:Theme.of(context).colorScheme.surface, builder:(ctx) => SafeArea(
    child:Padding(padding:const EdgeInsets.all(20),
      child:ConstrainedBox(constraints:BoxConstraints(maxHeight:MediaQuery.sizeOf(ctx).height*.72),
      child:SingleChildScrollView(child:FutureBuilder<List<MetaReaction>>(
      future:model.api.getPeopleWhoReacted(post.id,model.pageToken),builder:(ctx,snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Column(mainAxisSize:MainAxisSize.min,children:[
          Text('Consultando reações autorizadas…'),SizedBox(height:20),CircularProgressIndicator(),SizedBox(height:20)]);
        if (snapshot.hasError) return Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('Quem reagiu?',style:Theme.of(ctx).textTheme.titleLarge),const SizedBox(height:12),
          const InlineFeedback(isError:true,message:'A Meta não disponibilizou a lista de pessoas para esta publicação ou token. A contagem, quando disponível, continua visível.'),
          const SizedBox(height:9),const Text('A disponibilidade depende de permissões e regras de privacidade. Nenhum nome será estimado.'),
        ]);
        final people = snapshot.data ?? [];
        final named = people.where((p) => p.name != null && p.name!.trim().isNotEmpty).toList();
        return Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('Pessoas identificadas pela API',style:Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height:8),
          Text('Resultado parcial, sujeito a permissões e limites. ${people.length} reações retornadas nesta consulta.',style:Theme.of(ctx).textTheme.bodySmall),
          const SizedBox(height:12),
          if (named.isEmpty) const InlineFeedback(message:'A API não forneceu nomes identificáveis. Consulte a contagem de reações acima.'),
          for (final p in named.take(25)) ListTile(leading:const CircleAvatar(child:Icon(Icons.person_outline)),
            title:Text(p.name!),subtitle:Text(p.type)),
        ]);
      }),
    )))));
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key,required this.model});
  final AppModel model;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation:model,builder:(context,_) {
    final records = model.pageHistory;
    return Scaffold(appBar:AppBar(title:const Text('Histórico local')),
      body:ListView(padding:const EdgeInsets.all(16),children:[
        const UaiCard(child:Row(children:[Icon(Icons.save_outlined),SizedBox(width:12),Expanded(
          child:Text('Registros diários feitos somente quando você atualiza o aplicativo. Sem medições retroativas inventadas.'))])),
        const SectionTitle('Amostras guardadas'),
        if (records.isEmpty) const EmptyState(icon:Icons.timeline,title:'Sem histórico ainda',
          description:'Conecte a página e atualize o painel. As métricas disponíveis serão registradas uma vez por dia.'),
        for (final entry in records.reversed) ...[
          ListTile(leading:const Icon(Icons.calendar_today_outlined),title:Text((entry['date'] ?? '').toString()),
            subtitle:Text('Seguidores: ${formatCount(asCount(entry['followers']))}  •  Curtidas: ${formatCount(asCount(entry['likes']))}')),
          const Divider(height:1),
        ],
        const SizedBox(height:30),
        Text('Dados salvos apenas neste dispositivo; ao apagar dados do app, os registros também são apagados.',
          style:Theme.of(context).textTheme.bodySmall),
      ]));
  });
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key,required this.model,required this.showChanges});
  final AppModel model;
  final VoidCallback showChanges;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation:model,builder:(ctx,_) => Scaffold(
    appBar:AppBar(title:const Text('Ajustes')),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      const SectionTitle('Conexão com a Meta'),
      UaiCard(child:Column(children:[
        ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.key_outlined),
          title:const Text('Token de acesso'),subtitle:Text(model.token.isEmpty ? 'Não configurado':'Armazenado com segurança'),
          trailing:const Icon(Icons.chevron_right),onTap:() => showSetup(context,model)),
        const Divider(),
        ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.file_open_outlined),
          title:const Text('Importar token'),subtitle:const Text('TXT, ENV ou JSON usando seletor de documentos'),
          onTap:() => showSetup(context,model)),
        ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.copy_outlined),
          title:const Text('Copiar token'),subtitle:const Text('Copia para a área de transferência, após confirmação'),
          onTap:model.token.isEmpty ? null : () async {
            final confirmed = await confirmSheet(context,title:'Copiar credencial?',
              message:'O token ficará na área de transferência, onde outros aplicativos podem ter acesso em certas condições. Evite compartilhar.',
              action:'Copiar');
            if (!confirmed || !context.mounted) return;
            await Clipboard.setData(ClipboardData(text:model.token));
            if (context.mounted) notice(context,'Token copiado. Apague da área de transferência após o uso.');
          }),
        ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.file_download_outlined),
          title:const Text('Exportar token'),subtitle:const Text('Cópia sensível, nunca envie ao GitHub'),
          onTap:model.token.isEmpty ? null : () async {
            final confirmed = await confirmSheet(context,title:'Exportar credencial?',
              message:'Quem obtiver este arquivo poderá usar o token até que expire ou seja revogado. Exporte apenas para local privado.',
              action:'Exportar');
            if (!confirmed || !context.mounted) return;
            try {
              final saved = await TokenTransfer.exportToDocument(model.token);
              if (context.mounted) notice(context,saved ? 'Arquivo salvo no local escolhido.' : 'Exportação cancelada.');
            } catch (_) { if (context.mounted) notice(context,'Não foi possível exportar o token.'); }
          }),
        ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.open_in_new),
          title:const Text('Obter token (Meta Developers)'),onTap:() => openExternal(metaExplorer)),
        ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.info_outline),
          title:const Text('Documentação Pages API'),onTap:() => openExternal(metaDocs)),
      ])),
      const SectionTitle('Aparência'),
      UaiCard(child:Column(children:[
        Wrap(spacing:8,runSpacing:4,children:[
          ChoiceChip(label:const Text('Sistema'), selected:model.themeMode==ThemeMode.system,
            onSelected:(_) => model.setTheme(ThemeMode.system)),
          ChoiceChip(label:const Text('Claro'),selected:model.themeMode==ThemeMode.light,
            onSelected:(_) => model.setTheme(ThemeMode.light)),
          ChoiceChip(label:const Text('AMOLED'),selected:model.themeMode==ThemeMode.dark,
            onSelected:(_) => model.setTheme(ThemeMode.dark)),
        ]),
      ])),
      const SectionTitle('Privacidade'),
      ListTile(leading:const Icon(Icons.delete_outline),title:const Text('Remover tokens do aparelho'),
        subtitle:const Text('O histórico local permanece, mas fica separado por página.'),
        onTap:() async {
          final yes = await confirmSheet(context,title:'Remover credenciais?',
            message:'As credenciais armazenadas serão apagadas deste aparelho. Você poderá conectar novamente.',
            destructive:true,action:'Remover');
          if (yes) await model.removeCredentials();
        }),
      const SectionTitle('Sobre'),
      ListTile(leading:const Icon(Icons.new_releases_outlined),title:const Text('O que mudou?'),onTap:showChanges),
      ListTile(leading:const Icon(Icons.code),title:const Text('Uai, Não Parece Real'),
        subtitle:const Text('0.1.0-alpha.3 • build 3 • Flutter / Android\nAplicativo independente; não afiliado à Meta.')),
      const SizedBox(height:50),
    ])));
}
