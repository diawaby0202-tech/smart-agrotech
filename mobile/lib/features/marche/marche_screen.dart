import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/visuels.dart';
import '../../core/widgets.dart';
import '../auth/auth_provider.dart';
import '../auth/user.dart';
import 'annonce.dart';
import 'annonce_detail_screen.dart';
import 'annonce_form_screen.dart';
import 'annonce_repository.dart';

/// Module Marché, sur le modèle de la page « Marché agricole » du site.
class MarcheScreen extends StatefulWidget {
  const MarcheScreen({super.key});

  @override
  State<MarcheScreen> createState() => _MarcheScreenState();
}

class _MarcheScreenState extends State<MarcheScreen> {
  final _listKey = GlobalKey<AsyncViewState<List<Annonce>>>();
  final _recherche = TextEditingController();
  FiltreAnnonces _filtre = const FiltreAnnonces();
  bool _mesAnnonces = false;

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  void _reload() => _listKey.currentState?.reload();

  void _setFiltre(FiltreAnnonces filtre) {
    setState(() => _filtre = filtre);
    _reload();
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

  /// « Mes annonces » montre toutes les annonces du vendeur (même vendues),
  /// filtrées localement par catégorie et recherche.
  Future<List<Annonce>> _load() async {
    final repository = context.read<AnnonceRepository>();
    if (!_mesAnnonces) return repository.list(_filtre);
    final recherche = _filtre.recherche.toLowerCase();
    return (await repository.mesAnnonces())
        .where(
          (a) =>
              (_filtre.categorie == null || a.categorie == _filtre.categorie) &&
              a.titre.toLowerCase().contains(recherche),
        )
        .toList();
  }

  Future<void> _ouvrir(Widget ecran) async {
    final changed = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => ecran));
    if (changed == true) _reload();
  }

  Future<void> _supprimer(Annonce annonce) async {
    final ok = await confirmer(
      context,
      titre: 'Supprimer l\'annonce ?',
      message: '« ${annonce.titre} » ne sera plus visible sur le marché.',
    );
    if (!ok || !mounted) return;
    try {
      await context.read<AnnonceRepository>().delete(annonce.id!);
      _reload();
    } catch (e) {
      if (mounted) showMessage(context, messageErreur(e));
    }
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
    final role = context.watch<AuthProvider>().user?.role;
    final peutVendre = role != UserRole.acheteur;

    return Scaffold(
      body: SafeArea(
        child: AsyncView<List<Annonce>>(
          key: _listKey,
          load: _load,
          builder: (context, annonces) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              const BandeauModule(
                icone: '🛒',
                titre: 'Marché agricole',
                texte:
                    'Achetez et vendez des produits locaux, directement '
                    'entre producteurs et acheteurs.',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('marche-recherche'),
                      controller: _recherche,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (value) =>
                          _setFiltre(_avec(recherche: value.trim())),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un produit…',
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
                  if (peutVendre) ...[
                    const SizedBox(width: 8),
                    FilledButton(
                      key: const Key('marche-vendre'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 54),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onPressed: () => _ouvrir(const AnnonceFormScreen()),
                      child: const Text('+ Vendre'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final categorie in [null, ...CategorieAnnonce.values])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(categorie?.label ?? 'Tout'),
                          selected: _filtre.categorie == categorie,
                          showCheckmark: false,
                          onSelected: (_) => _setFiltre(
                            categorie == null
                                ? _avec(effacerCategorie: true)
                                : _avec(categorie: categorie),
                          ),
                        ),
                      ),
                    FilterChip(
                      key: const Key('marche-mes-annonces'),
                      label: const Text('Mes annonces'),
                      selected: _mesAnnonces,
                      onSelected: (valeur) {
                        setState(() => _mesAnnonces = valeur);
                        _reload();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (annonces.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    _mesAnnonces
                        ? 'Vous n\'avez pas encore d\'annonce.'
                        : 'Aucune annonce ne correspond.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final annonce in annonces)
                _CarteAnnonce(
                  annonce: annonce,
                  onOuvrir: () =>
                      _ouvrir(AnnonceDetailScreen(annonce: annonce)),
                  onModifier: () =>
                      _ouvrir(AnnonceFormScreen(annonce: annonce)),
                  onSupprimer: () => _supprimer(annonce),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Photo de l'annonce, sinon l'image de sa catégorie (comme sur le site).
String imageAnnonce(Annonce annonce) => annonce.photoUrl.isNotEmpty
    ? annonce.photoUrl
    : visuelCategorie(annonce.categorie.apiValue).image;

class _CarteAnnonce extends StatelessWidget {
  const _CarteAnnonce({
    required this.annonce,
    required this.onOuvrir,
    required this.onModifier,
    required this.onSupprimer,
  });

  final Annonce annonce;
  final VoidCallback onOuvrir;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CartePhoto(
      image: imageAnnonce(annonce),
      onTap: onOuvrir,
      badgeHaut: annonce.zone.isEmpty
          ? null
          : Etiquette(
              '📍 ${annonce.zone}',
              fond: Colors.white,
              couleur: Couleurs.encre,
            ),
      badgeBas: annonce.statut == StatutAnnonce.disponible
          ? null
          : Etiquette(annonce.statut.label, fond: Couleurs.or500),
      children: [
        Text(
          annonce.categorie.label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: Couleurs.vert600,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(annonce.titre, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          formatPrix(annonce.prix),
          style: theme.textTheme.titleLarge?.copyWith(color: Couleurs.vert600),
        ),
        if (annonce.quantite.isNotEmpty)
          LigneInfo('📦', 'Quantité : ${annonce.quantite}'),
        if (annonce.vendeurNom.isNotEmpty) LigneInfo('👤', annonce.vendeurNom),
        const SizedBox(height: 12),
        if (annonce.estProprietaire)
          Row(
            children: [
              BoutonCarte('Modifier', onPressed: onModifier),
              const SizedBox(width: 8),
              BoutonCarte('Supprimer', danger: true, onPressed: onSupprimer),
            ],
          )
        else
          SizedBox(
            width: double.infinity,
            child: BoutonCarte('Contacter le vendeur', onPressed: onOuvrir),
          ),
      ],
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
