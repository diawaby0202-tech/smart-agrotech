import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/visuels.dart';
import '../../core/widgets.dart';
import '../home/menu.dart';
import 'animal_detail_screen.dart';
import 'animal_form_screen.dart';
import 'elevage_models.dart';
import 'elevage_repository.dart';
import 'suivi_form_screen.dart';

/// Module Élevage, sur le modèle de la page « Gestion de l'élevage » du site.
class ElevageScreen extends StatefulWidget {
  const ElevageScreen({super.key});

  @override
  State<ElevageScreen> createState() => _ElevageScreenState();
}

typedef _Troupeau = ({List<Animal> animaux, List<SuiviSanitaire> suivis});

class _ElevageScreenState extends State<ElevageScreen> {
  final _listKey = GlobalKey<AsyncViewState<_Troupeau>>();
  String? _filtre;

  void _reload() => _listKey.currentState?.reload();

  Future<_Troupeau> _load() async {
    final repository = context.read<ElevageRepository>();
    final animaux = await repository.animaux();
    final suivis = await repository.tousLesSuivis();
    return (animaux: animaux, suivis: suivis);
  }

  Future<void> _ouvrir(Widget ecran) async {
    await Navigator.of(
      context,
    ).push<Object>(MaterialPageRoute(builder: (_) => ecran));
    _reload();
  }

  Future<void> _supprimer(Animal animal) async {
    final ok = await confirmer(
      context,
      titre: 'Supprimer cet animal ?',
      message: '« ${animal.titre} » et son suivi sanitaire seront supprimés.',
    );
    if (!ok || !mounted) return;
    try {
      await context.read<ElevageRepository>().deleteAnimal(animal.id!);
      _reload();
    } catch (e) {
      if (mounted) showMessage(context, messageErreur(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BarreMarque(),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-elevage',
        onPressed: () => _ouvrir(const AnimalFormScreen()),
        icon: const Icon(Icons.add),
        label: const Text('Nouvel animal'),
      ),
      body: SafeArea(
        child: AsyncView<_Troupeau>(
          key: _listKey,
          load: _load,
          builder: (context, troupeau) {
            final especes = {
              for (final a in troupeau.animaux) a.espece,
            }.toList()..sort();
            final affiches = _filtre == null
                ? troupeau.animaux
                : troupeau.animaux.where((a) => a.espece == _filtre).toList();
            final tetes = troupeau.animaux.fold<int>(
              0,
              (s, a) => s + a.effectif,
            );
            final etats = {
              for (final a in troupeau.animaux)
                a.id: etatAnimal(a, troupeau.suivis),
            };

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                const BandeauModule(
                  titre: 'Gestion de l’élevage',
                  texte:
                      'Les soins à venir et les informations de chaque bête, '
                      'au même endroit.',
                  image: 'assets/img/elevage-bovin.jpg',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CaseStat(
                        valeur: '${troupeau.animaux.length}',
                        libelle: 'Fiches',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CaseStat(valeur: '$tetes', libelle: 'Têtes'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CaseStat(
                        valeur:
                            '${etats.values.where((e) => e != EtatSante.bon).length}',
                        libelle: 'À surveiller',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (especes.length > 1)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final espece in [null, ...especes])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(espece ?? 'Tous'),
                              selected: _filtre == espece,
                              showCheckmark: false,
                              onSelected: (_) =>
                                  setState(() => _filtre = espece),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                if (affiches.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'Aucun animal.\nEnregistrez un animal ou un lot.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (var i = 0; i < affiches.length; i += 2) ...[
                  if (i > 0) const SizedBox(height: 12),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var j = i; j < i + 2; j++) ...[
                          if (j > i) const SizedBox(width: 12),
                          if (j < affiches.length)
                            Expanded(
                              child: _CarteAnimal(
                                animal: affiches[j],
                                etat: etats[affiches[j].id]!,
                                prochain: prochainSoin(
                                  affiches[j],
                                  troupeau.suivis,
                                ),
                                onOuvrir: () => _ouvrir(
                                  AnimalDetailScreen(animal: affiches[j]),
                                ),
                                onSoin: () => _ouvrir(
                                  SuiviFormScreen(animal: affiches[j]),
                                ),
                                onModifier: () => _ouvrir(
                                  AnimalFormScreen(animal: affiches[j]),
                                ),
                                onSupprimer: () => _supprimer(affiches[j]),
                              ),
                            )
                          else
                            const Spacer(),
                        ],
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

enum EtatSante {
  bon('Bonne santé', Couleurs.vert600),
  attention('À surveiller', Couleurs.info),
  critique('Urgent', Couleurs.danger);

  const EtatSante(this.label, this.couleur);

  final String label;
  final Color couleur;
}

/// Prochain soin prévu d'un animal, en ignorant une échéance déjà couverte
/// par un soin plus récent du même type (même règle que le site).
SuiviSanitaire? prochainSoin(Animal animal, List<SuiviSanitaire> suivis) {
  final siens = suivis.where((s) => s.animalId == animal.id).toList();
  final aVenir = siens.where((s) => s.prochaineEcheance != null).toList()
    ..sort((a, b) => a.prochaineEcheance!.compareTo(b.prochaineEcheance!));
  for (final soin in aVenir) {
    final couvert = siens.any(
      (autre) => autre.type == soin.type && autre.date.isAfter(soin.date),
    );
    if (!couvert) return soin;
  }
  return null;
}

EtatSante etatAnimal(Animal animal, List<SuiviSanitaire> suivis) {
  final soin = prochainSoin(animal, suivis);
  if (soin == null) return EtatSante.bon;
  final ecart = joursRestants(soin.prochaineEcheance!);
  if (ecart < 0) return EtatSante.critique;
  if (ecart <= 7) return EtatSante.attention;
  return EtatSante.bon;
}

String ageAnimal(DateTime? naissance) {
  if (naissance == null) return 'Âge non renseigné';
  final mois = (DateTime.now().difference(naissance).inDays / 30.44).floor();
  if (mois < 0) return 'Âge non renseigné';
  if (mois < 12) return '$mois mois';
  final ans = mois ~/ 12;
  return '$ans an${ans > 1 ? 's' : ''}';
}

class _CarteAnimal extends StatelessWidget {
  const _CarteAnimal({
    required this.animal,
    required this.etat,
    required this.prochain,
    required this.onOuvrir,
    required this.onSoin,
    required this.onModifier,
    required this.onSupprimer,
  });

  final Animal animal;
  final EtatSante etat;
  final SuiviSanitaire? prochain;
  final VoidCallback onOuvrir;
  final VoidCallback onSoin;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nom = animal.identifiant.isEmpty ? animal.espece : animal.identifiant;
    final soin = prochain;
    final couleurEtat = etat == EtatSante.attention ? Couleurs.or600 : etat.couleur;
    final detail = [
      animal.espece,
      if (animal.race.isNotEmpty) animal.race,
    ].join(', ');
    final texteSoin = soin == null
        ? 'Aucun soin planifié'
        : '${soin.type.label} — '
              '${formatDateLongue(soin.prochaineEcheance, annee: false)} '
              '(${_ecart(soin.prochaineEcheance!)})';

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOuvrir,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.12,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ImageSource(
                    animal.image?.isNotEmpty == true
                        ? animal.image!
                        : visuelEspece(animal.espece).image,
                  ),
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
                        etat.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: couleurEtat,
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
                          nom,
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
                        child: PopupMenuButton<String>(
                          tooltip: 'Actions',
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.more_vert,
                            size: 20,
                            color: Couleurs.ardoise500,
                          ),
                          onSelected: (action) {
                            switch (action) {
                              case 'soin':
                                onSoin();
                              case 'modifier':
                                onModifier();
                              case 'supprimer':
                                onSupprimer();
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'soin', child: Text('+ Soin')),
                            PopupMenuItem(
                              value: 'modifier',
                              child: Text('Modifier'),
                            ),
                            PopupMenuItem(
                              value: 'supprimer',
                              child: Text('Supprimer'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    animal.estLot
                        ? '${animal.effectif} têtes'
                        : ageAnimal(animal.dateNaissance),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Couleurs.vert700,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
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
                      texteSoin,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: etat == EtatSante.critique
                            ? Couleurs.danger
                            : Couleurs.ardoise700,
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

  static String _ecart(DateTime date) {
    final jours = joursRestants(date);
    if (jours == 0) return "aujourd'hui";
    if (jours > 0) return 'dans $jours j';
    return 'en retard de ${-jours} j';
  }
}
