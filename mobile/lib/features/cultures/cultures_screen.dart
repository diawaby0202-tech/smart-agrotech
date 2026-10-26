import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/visuels.dart';
import '../../core/widgets.dart';
import '../home/menu.dart';
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
            final affichees = _filtre == null
                ? parcelles
                : parcelles.where((p) => p.culture == _filtre).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                const BandeauModule(
                  icone: '🌾',
                  titre: 'Suivi des cultures',
                  texte:
                      'Suivez vos parcelles de la semence à la récolte, '
                      'anticipez chaque étape.',
                ),
                const SizedBox(height: 16),
                _Statistiques(parcelles: parcelles),
                const SizedBox(height: 16),
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
                for (final parcelle in affichees)
                  _CarteParcelle(
                    parcelle: parcelle,
                    onModifier: () => _openForm(parcelle),
                    onSupprimer: () => _supprimer(parcelle),
                  ),
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
  });

  final Parcelle parcelle;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avancement = progression(parcelle);
    final rappel = rappelRecolte(parcelle);
    final enRetard = rappel?.contains('dépassée') ?? false;
    final couleurStatut = switch (parcelle.statut) {
      StatutParcelle.preparation || StatutParcelle.semee => Couleurs.info,
      StatutParcelle.croissance => Couleurs.vert600,
      StatutParcelle.recoltee => Couleurs.or500,
    };

    return CartePhoto(
      image: visuelCulture(parcelle.culture).image,
      onTap: onModifier,
      badgeBas: Etiquette(parcelle.statut.label, fond: couleurStatut),
      children: [
        Text(
          '${parcelle.nom} · ${parcelle.culture}',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        LigneInfo(
          '📐',
          [
            '${formatNombre(parcelle.superficie)} ha',
            if (parcelle.localisation.isNotEmpty) parcelle.localisation,
          ].join(' · '),
        ),
        LigneInfo('🌱', 'Semis : ${formatDateLongue(parcelle.dateSemis)}'),
        LigneInfo(
          '🧺',
          'Récolte : ${formatDateLongue(parcelle.dateRecoltePrevue)}',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text('Avancement', style: theme.textTheme.bodySmall),
            const Spacer(),
            Text('$avancement%', style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(value: avancement / 100, minHeight: 8),
        ),
        if (rappel != null) ...[
          const SizedBox(height: 12),
          Encadre(
            icone: '⚠️',
            texte: rappel,
            fond: enRetard ? Couleurs.dangerClair : Couleurs.or100,
            couleur: enRetard ? Couleurs.danger : Couleurs.or600,
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            BoutonCarte('Modifier', onPressed: onModifier),
            const SizedBox(width: 8),
            BoutonCarte('Supprimer', danger: true, onPressed: onSupprimer),
          ],
        ),
      ],
    );
  }
}
