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
                  icone: '🐄',
                  titre: 'Gestion de l’élevage',
                  texte:
                      'Un troupeau en bonne santé, suivi au plus près : '
                      'soins, vaccins, alertes.',
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
                for (final animal in affiches)
                  _CarteAnimal(
                    animal: animal,
                    etat: etats[animal.id]!,
                    prochain: prochainSoin(animal, troupeau.suivis),
                    onOuvrir: () => _ouvrir(AnimalDetailScreen(animal: animal)),
                    onSoin: () => _ouvrir(SuiviFormScreen(animal: animal)),
                    onModifier: () => _ouvrir(AnimalFormScreen(animal: animal)),
                    onSupprimer: () => _supprimer(animal),
                  ),
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

    return CartePhoto(
      image: visuelEspece(animal.espece).image,
      onTap: onOuvrir,
      badgeBas: Etiquette(etat.label, fond: etat.couleur),
      children: [
        Text(
          animal.estLot ? '$nom (${animal.effectif} têtes)' : nom,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        LigneInfo(
          '🏷️',
          [animal.espece, if (animal.race.isNotEmpty) animal.race].join(' · '),
        ),
        LigneInfo('🎂', ageAnimal(animal.dateNaissance)),
        LigneInfo('💚', etat.label),
        const SizedBox(height: 12),
        if (soin == null)
          const Encadre(
            icone: '✅',
            texte: 'Aucun soin planifié',
            fond: Couleurs.vert50,
            couleur: Couleurs.vert700,
          )
        else
          Encadre(
            icone: '💉',
            texte:
                '${soin.type.label} — '
                '${formatDateLongue(soin.prochaineEcheance, annee: false)} '
                '(${_ecart(soin.prochaineEcheance!)})',
            fond: etat == EtatSante.critique
                ? Couleurs.dangerClair
                : Couleurs.or100,
            couleur: etat == EtatSante.critique
                ? Couleurs.danger
                : Couleurs.or600,
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            BoutonCarte('+ Soin', onPressed: onSoin),
            BoutonCarte('Modifier', onPressed: onModifier),
            BoutonCarte('Supprimer', danger: true, onPressed: onSupprimer),
          ],
        ),
      ],
    );
  }

  static String _ecart(DateTime date) {
    final jours = joursRestants(date);
    if (jours == 0) return "aujourd'hui";
    if (jours > 0) return 'dans $jours j';
    return 'en retard de ${-jours} j';
  }
}
