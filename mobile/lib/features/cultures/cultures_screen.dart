import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/visuels.dart';
import '../../core/widgets.dart';
import '../home/menu.dart';
import 'calendrier_recoltes_screen.dart';
import 'historique_recoltes_screen.dart';
import 'parcelle.dart';
import 'parcelle_form_screen.dart';
import 'parcelle_repository.dart';

/// Module Cultures, sur le modèle de la page « Suivi des cultures » du site.
class CulturesScreen extends StatefulWidget {
  const CulturesScreen({super.key});

  @override
  State<CulturesScreen> createState() => _CulturesScreenState();
}

class _CulturesScreenState extends State<CulturesScreen> {
  final _listKey = GlobalKey<AsyncViewState<List<Parcelle>>>();
  String? _filtre;
  String _recherche = '';

  void _reload() => _listKey.currentState?.reload();

  Future<void> _openForm([Parcelle? parcelle]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ParcelleFormScreen(parcelle: parcelle)),
    );
    if (changed == true) _reload();
  }

  Future<void> _supprimer(Parcelle parcelle) async {
    final ok = await confirmer(
      context,
      titre: 'Supprimer la parcelle ?',
      message: 'La parcelle « ${parcelle.nom} » sera supprimée.',
    );
    if (!ok || !mounted) return;
    try {
      await context.read<ParcelleRepository>().delete(parcelle.id!);
      _reload();
    } catch (e) {
      if (mounted) showMessage(context, messageErreur(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<ParcelleRepository>();

    return Scaffold(
      appBar: const BarreMarque(),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-cultures',
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle parcelle'),
      ),
      body: SafeArea(
        child: AsyncView<List<Parcelle>>(
          key: _listKey,
          load: repository.list,
          builder: (context, parcelles) {
            final cultures = {for (final p in parcelles) p.culture}.toList()
              ..sort();
            final recherche = _recherche.trim().toLowerCase();
            final affichees = parcelles.where((parcelle) {
              final correspondCategorie =
                  _filtre == null || parcelle.culture == _filtre;
              final correspondRecherche =
                  recherche.isEmpty ||
                  parcelle.nom.toLowerCase().contains(recherche) ||
                  parcelle.culture.toLowerCase().contains(recherche) ||
                  parcelle.localisation.toLowerCase().contains(recherche);
              return correspondCategorie && correspondRecherche;
            }).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                const BandeauModule(
                  titre: 'Suivi des cultures',
                  texte:
                      'De la préparation à la récolte, gardez un œil sur '
                      'chaque parcelle.',
                  image: 'assets/img/culture-mil.jpg',
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  key: const Key('cultures-calendrier'),
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => const CalendrierRecoltesScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Calendrier des récoltes'),
                ),
                const SizedBox(height: 16),
                _Statistiques(parcelles: parcelles),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('cultures-recherche'),
                  onChanged: (valeur) => setState(() => _recherche = valeur),
                  decoration: const InputDecoration(
                    hintText: 'Rechercher une culture',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                if (cultures.length > 1)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final culture in [null, ...cultures])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(culture ?? 'Toutes'),
                              selected: _filtre == culture,
                              showCheckmark: false,
                              onSelected: (_) =>
                                  setState(() => _filtre = culture),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                if (affichees.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'Aucune parcelle.\nAjoutez votre première parcelle.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (affichees.isNotEmpty)
                  for (var i = 0; i < affichees.length; i += 2) ...[
                    if (i > 0) const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _CarteParcelle(
                              parcelle: affichees[i],
                              onModifier: () => _openForm(affichees[i]),
                              onSupprimer: () => _supprimer(affichees[i]),
                              onHistorique: affichees[i].id == null
                                  ? null
                                  : () => Navigator.of(context).push<void>(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            HistoriqueRecoltesScreen(
                                              parcelle: affichees[i],
                                            ),
                                      ),
                                    ),
                            ),
                          ),
                          if (i + 1 < affichees.length) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: _CarteParcelle(
                                parcelle: affichees[i + 1],
                                onModifier: () => _openForm(affichees[i + 1]),
                                onSupprimer: () => _supprimer(affichees[i + 1]),
                                onHistorique: affichees[i + 1].id == null
                                    ? null
                                    : () => Navigator.of(context).push<void>(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              HistoriqueRecoltesScreen(
                                                parcelle: affichees[i + 1],
                                              ),
                                        ),
                                      ),
                              ),
                            ),
                          ] else
                            const Spacer(),
                        ],
                      ),
                    ),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Avancement de la culture en %, même calcul que le site : d'après les
/// dates de semis et de récolte, sinon d'après l'étape.
int progression(Parcelle parcelle) {
  if (parcelle.statut == StatutParcelle.recoltee) return 100;
  final semis = parcelle.dateSemis;
  final recolte = parcelle.dateRecoltePrevue;
  if (semis != null && recolte != null && recolte.isAfter(semis)) {
    final total = recolte.difference(semis).inMinutes;
    final ecoule = DateTime.now().difference(semis).inMinutes;
    return (ecoule / total * 100).round().clamp(0, 99);
  }
  return switch (parcelle.statut) {
    StatutParcelle.preparation => 5,
    StatutParcelle.semee => 20,
    StatutParcelle.croissance => 60,
    StatutParcelle.recoltee => 100,
  };
}

/// Rappel affiché sur la carte, comme sur le site.
String? rappelRecolte(Parcelle parcelle) {
  final recolte = parcelle.dateRecoltePrevue;
  if (parcelle.statut == StatutParcelle.recoltee || recolte == null) {
    return null;
  }
  final jours = joursRestants(recolte);
  if (jours < 0) return 'Récolte prévue dépassée de ${-jours} jour(s)';
  if (jours == 0) return "Récolte prévue aujourd'hui";
  return 'Récolte prévue dans $jours jour(s)';
}

class _Statistiques extends StatelessWidget {
  const _Statistiques({required this.parcelles});

  final List<Parcelle> parcelles;

  @override
  Widget build(BuildContext context) {
    final enCours = parcelles
        .where((p) => p.statut != StatutParcelle.recoltee)
        .toList();
    final surface = parcelles.fold<double>(0, (s, p) => s + p.superficie);
    final recoltes =
        enCours
            .map((p) => p.dateRecoltePrevue)
            .whereType<DateTime>()
            .where((d) => joursRestants(d) >= 0)
            .toList()
          ..sort();

    final cases = [
      CaseStat(valeur: '${parcelles.length}', libelle: 'Parcelles suivies'),
      CaseStat(
        valeur: '${formatNombre(double.parse(surface.toStringAsFixed(1)))} ha',
        libelle: 'Surface totale',
      ),
      CaseStat(
        valeur: recoltes.isEmpty ? '—' : formatDateCourte(recoltes.first),
        libelle: 'Prochaine récolte',
      ),
      CaseStat(valeur: '${enCours.length}', libelle: 'Cultures en cours'),
    ];
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: cases[0]),
            const SizedBox(width: 10),
            Expanded(child: cases[1]),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: cases[2]),
            const SizedBox(width: 10),
            Expanded(child: cases[3]),
          ],
        ),
      ],
    );
  }
}

class _CarteParcelle extends StatelessWidget {
  const _CarteParcelle({
    required this.parcelle,
    required this.onModifier,
    required this.onSupprimer,
    required this.onHistorique,
  });

  final Parcelle parcelle;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;
  final VoidCallback? onHistorique;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rappel = rappelRecolte(parcelle);
    final enRetard = rappel?.contains('dépassée') ?? false;
    final couleurStatut = switch (parcelle.statut) {
      StatutParcelle.preparation || StatutParcelle.semee => Couleurs.info,
      StatutParcelle.croissance => Couleurs.vert600,
      StatutParcelle.recoltee => Couleurs.or600,
    };
    final image = parcelle.image?.isNotEmpty == true
        ? parcelle.image!
        : visuelCulture(parcelle.culture).image;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onModifier,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo pleine largeur, avec le statut en pastille en haut à droite.
            AspectRatio(
              aspectRatio: 1.12,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ImageSource(image),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        parcelle.statut.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: couleurStatut,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          parcelle.culture,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Couleurs.encre,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: PopupMenuButton<_ActionCarte>(
                          tooltip: 'Actions',
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.more_vert,
                            size: 20,
                            color: Couleurs.ardoise500,
                          ),
                          onSelected: (action) {
                            switch (action) {
                              case _ActionCarte.modifier:
                                onModifier();
                              case _ActionCarte.historique:
                                onHistorique?.call();
                              case _ActionCarte.supprimer:
                                onSupprimer();
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: _ActionCarte.modifier,
                              child: Text('Modifier'),
                            ),
                            if (onHistorique != null)
                              PopupMenuItem(
                                key: Key('parcelle-recoltes-${parcelle.id}'),
                                value: _ActionCarte.historique,
                                child: const Text('Historique des récoltes'),
                              ),
                            const PopupMenuItem(
                              value: _ActionCarte.supprimer,
                              child: Text('Supprimer'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatNombre(parcelle.superficie)} ha',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Couleurs.vert700,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Parcelle · ${parcelle.nom}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Couleurs.ardoise500,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      parcelle.dateRecoltePrevue == null
                          ? 'Cycle non documenté'
                          : rappel ?? 'Récolte prévue',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: enRetard ? Couleurs.danger : Couleurs.ardoise700,
                        fontSize: 12.5,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ActionCarte { modifier, historique, supprimer }
