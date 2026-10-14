import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/widgets.dart';
import 'annonce.dart';
import 'annonce_detail_screen.dart';
import 'annonce_form_screen.dart';
import 'annonce_repository.dart';

/// Module Marché : recherche d'annonces et gestion de ses propres annonces.
class MarcheScreen extends StatefulWidget {
  const MarcheScreen({super.key});

  @override
  State<MarcheScreen> createState() => _MarcheScreenState();
}

class _MarcheScreenState extends State<MarcheScreen> {
  final _listKey = GlobalKey<AsyncViewState<List<Annonce>>>();
  final _mesAnnoncesKey = GlobalKey<AsyncViewState<List<Annonce>>>();
  final _recherche = TextEditingController();
  FiltreAnnonces _filtre = const FiltreAnnonces();

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  void _reload() {
    _listKey.currentState?.reload();
    _mesAnnoncesKey.currentState?.reload();
  }

  void _setFiltre(FiltreAnnonces filtre) {
    setState(() => _filtre = filtre);
    _listKey.currentState?.reload();
  }

  FiltreAnnonces _avec({
    String? recherche,
    CategorieAnnonce? categorie,
    bool effacerCategorie = false,
  }) => FiltreAnnonces(
    recherche: recherche ?? _filtre.recherche,
    categorie: effacerCategorie ? null : categorie ?? _filtre.categorie,
    zone: _filtre.zone,
    prixMin: _filtre.prixMin,
    prixMax: _filtre.prixMax,
  );

  Future<void> _openDetail(Annonce annonce) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AnnonceDetailScreen(annonce: annonce)),
    );
    if (changed == true) _reload();
  }

  Future<void> _publier() async {
    final changed = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AnnonceFormScreen()));
    if (changed == true) _reload();
  }

  Future<void> _openFiltres() async {
    final filtre = await showModalBottomSheet<FiltreAnnonces>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FiltresSheet(filtre: _filtre),
    );
    if (filtre != null) _setFiltre(filtre);
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<AnnonceRepository>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Marché'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Annonces'),
              Tab(text: 'Mes annonces'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _publier,
          icon: const Icon(Icons.add),
          label: const Text('Publier'),
        ),
        body: TabBarView(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: TextField(
                    key: const Key('marche-recherche'),
                    controller: _recherche,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) =>
                        _setFiltre(_avec(recherche: value.trim())),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un produit',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        tooltip: 'Zone et prix',
                        icon: Badge(
                          isLabelVisible: _filtre.aDesCriteresAvances,
                          child: const Icon(Icons.tune),
                        ),
                        onPressed: _openFiltres,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 56,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      for (final categorie in CategorieAnnonce.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(categorie.label),
                            selected: _filtre.categorie == categorie,
                            onSelected: (selected) => _setFiltre(
                              selected
                                  ? _avec(categorie: categorie)
                                  : _avec(effacerCategorie: true),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: AsyncView<List<Annonce>>(
                    key: _listKey,
                    load: () => repository.list(_filtre),
                    builder: (context, annonces) => annonces.isEmpty
                        ? const MessageView(
                            icon: Icons.storefront,
                            message: 'Aucune annonce ne correspond.',
                          )
                        : _AnnonceList(annonces: annonces, onTap: _openDetail),
                  ),
                ),
              ],
            ),
            AsyncView<List<Annonce>>(
              key: _mesAnnoncesKey,
              load: repository.mesAnnonces,
              builder: (context, annonces) => annonces.isEmpty
                  ? const MessageView(
                      icon: Icons.sell_outlined,
                      message:
                          'Vous n\'avez pas encore d\'annonce.\n'
                          'Publiez votre premier produit.',
                    )
                  : _AnnonceList(
                      annonces: annonces,
                      onTap: _openDetail,
                      afficherStatut: true,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnonceList extends StatelessWidget {
  const _AnnonceList({
    required this.annonces,
    required this.onTap,
    this.afficherStatut = false,
  });

  final List<Annonce> annonces;
  final ValueChanged<Annonce> onTap;
  final bool afficherStatut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
      itemCount: annonces.length,
      itemBuilder: (context, index) {
        final annonce = annonces[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            onTap: () => onTap(annonce),
            leading: AnnoncePhoto(url: annonce.photoUrl, size: 56),
            title: Text(annonce.titre),
            subtitle: Text(
              [
                annonce.categorie.label,
                if (annonce.quantite.isNotEmpty) annonce.quantite,
                if (annonce.zone.isNotEmpty) annonce.zone,
                if (afficherStatut) annonce.statut.label,
              ].join(' · '),
            ),
            trailing: Text(
              formatPrix(annonce.prix),
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Photo d'une annonce, ou une icône si elle n'en a pas.
class AnnoncePhoto extends StatelessWidget {
  const AnnoncePhoto({super.key, required this.url, required this.size});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(Icons.image_outlined, size: size / 2),
    );
    if (url.isEmpty) return placeholder;
    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

/// Filtres avancés : zone géographique et fourchette de prix.
class _FiltresSheet extends StatefulWidget {
  const _FiltresSheet({required this.filtre});

  final FiltreAnnonces filtre;

  @override
  State<_FiltresSheet> createState() => _FiltresSheetState();
}

class _FiltresSheetState extends State<_FiltresSheet> {
  late final _zone = TextEditingController(text: widget.filtre.zone);
  late final _prixMin = TextEditingController(
    text: widget.filtre.prixMin?.toString(),
  );
  late final _prixMax = TextEditingController(
    text: widget.filtre.prixMax?.toString(),
  );

  @override
  void dispose() {
    _zone.dispose();
    _prixMin.dispose();
    _prixMax.dispose();
    super.dispose();
  }

  void _appliquer({bool effacer = false}) {
    Navigator.of(context).pop(
      FiltreAnnonces(
        recherche: widget.filtre.recherche,
        categorie: widget.filtre.categorie,
        zone: effacer ? '' : _zone.text.trim(),
        prixMin: effacer ? null : int.tryParse(_prixMin.text.trim()),
        prixMax: effacer ? null : int.tryParse(_prixMax.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Filtres', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            key: const Key('filtre-zone'),
            controller: _zone,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Zone',
              hintText: 'Dakar, Thiès, Kaolack…',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _prixMin,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Prix min',
                    suffixText: 'FCFA',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _prixMax,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Prix max',
                    suffixText: 'FCFA',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('filtre-appliquer'),
            onPressed: _appliquer,
            child: const Text('Appliquer'),
          ),
          TextButton(
            onPressed: () => _appliquer(effacer: true),
            child: const Text('Effacer les filtres'),
          ),
        ],
      ),
    );
  }
}
