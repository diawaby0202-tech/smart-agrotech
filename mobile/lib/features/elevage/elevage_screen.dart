import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/widgets.dart';
import 'animal_detail_screen.dart';
import 'animal_form_screen.dart';
import 'elevage_models.dart';
import 'elevage_repository.dart';

/// Module Élevage : animaux / lots et échéances sanitaires à venir.
class ElevageScreen extends StatefulWidget {
  const ElevageScreen({super.key});

  @override
  State<ElevageScreen> createState() => _ElevageScreenState();
}

/// Échéances à venir, avec les animaux concernés pour afficher leur nom.
typedef _Echeances = ({List<SuiviSanitaire> suivis, Map<int, Animal> animaux});

class _ElevageScreenState extends State<ElevageScreen> {
  final _animauxKey = GlobalKey<AsyncViewState<List<Animal>>>();
  final _echeancesKey = GlobalKey<AsyncViewState<_Echeances>>();

  void _reload() {
    _animauxKey.currentState?.reload();
    _echeancesKey.currentState?.reload();
  }

  Future<_Echeances> _loadEcheances() async {
    final repository = context.read<ElevageRepository>();
    final suivis = await repository.echeances();
    final animaux = await repository.animaux();
    return (suivis: suivis, animaux: {for (final a in animaux) a.id!: a});
  }

  Future<void> _openDetail(Animal animal) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => AnimalDetailScreen(animal: animal)),
    );
    _reload();
  }

  Future<void> _addAnimal() async {
    final changed = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AnimalFormScreen()));
    if (changed == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<ElevageRepository>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Élevage'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Animaux'),
              Tab(text: 'Échéances'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addAnimal,
          icon: const Icon(Icons.add),
          label: const Text('Animal'),
        ),
        body: TabBarView(
          children: [
            AsyncView<List<Animal>>(
              key: _animauxKey,
              load: repository.animaux,
              builder: (context, animaux) => animaux.isEmpty
                  ? const MessageView(
                      icon: Icons.pets,
                      message:
                          'Aucun animal.\nEnregistrez un animal ou un lot.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                      itemCount: animaux.length,
                      itemBuilder: (context, index) {
                        final animal = animaux[index];
                        return Card(
                          child: ListTile(
                            onTap: () => _openDetail(animal),
                            leading: const CircleAvatar(
                              child: Icon(Icons.pets),
                            ),
                            title: Text(animal.titre),
                            subtitle: Text(
                              [
                                if (animal.race.isNotEmpty) animal.race,
                                animal.estLot
                                    ? 'Lot de ${animal.effectif}'
                                    : 'Animal seul',
                              ].join(' · '),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        );
                      },
                    ),
            ),
            AsyncView<_Echeances>(
              key: _echeancesKey,
              load: _loadEcheances,
              builder: (context, data) => data.suivis.isEmpty
                  ? const MessageView(
                      icon: Icons.event_available,
                      message: 'Aucune échéance dans les 30 prochains jours.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                      itemCount: data.suivis.length,
                      itemBuilder: (context, index) {
                        final suivi = data.suivis[index];
                        final animal = data.animaux[suivi.animalId];
                        final urgent =
                            joursRestants(suivi.prochaineEcheance!) <= 2;
                        final color = urgent
                            ? Theme.of(context).colorScheme.error
                            : null;
                        return Card(
                          child: ListTile(
                            onTap: animal == null
                                ? null
                                : () => _openDetail(animal),
                            leading: Icon(Icons.vaccines, color: color),
                            title: Text(
                              '${suivi.type.label} — ${animal?.titre ?? ''}',
                            ),
                            subtitle: Text(
                              'Prévu le ${formatDate(suivi.prochaineEcheance)}',
                            ),
                            trailing: Text(
                              formatEcheance(suivi.prochaineEcheance!),
                              style: TextStyle(color: color),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
