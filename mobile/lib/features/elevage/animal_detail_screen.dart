import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/widgets.dart';
import 'animal_form_screen.dart';
import 'elevage_models.dart';
import 'elevage_repository.dart';
import 'suivi_form_screen.dart';

/// Fiche d'un animal ou d'un lot, avec son historique sanitaire (RF-11).
class AnimalDetailScreen extends StatefulWidget {
  const AnimalDetailScreen({super.key, required this.animal});

  final Animal animal;

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  final _suivisKey = GlobalKey<AsyncViewState<List<SuiviSanitaire>>>();
  late Animal _animal = widget.animal;

  Future<void> _edit() async {
    final result = await Navigator.of(context).push<Object>(
      MaterialPageRoute(builder: (_) => AnimalFormScreen(animal: _animal)),
    );
    if (!mounted) return;
    if (result is Animal) {
      setState(() => _animal = result);
    } else if (result == true) {
      // L'animal a été supprimé depuis le formulaire.
      Navigator.of(context).pop();
    }
  }

  Future<void> _addSuivi() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SuiviFormScreen(animal: _animal)),
    );
    if (changed == true) _suivisKey.currentState?.reload();
  }

  Future<void> _deleteSuivi(SuiviSanitaire suivi) async {
    final ok = await confirmer(
      context,
      titre: 'Supprimer ce suivi ?',
      message: '${suivi.type.label} du ${formatDate(suivi.date)}',
    );
    if (!ok || !mounted) return;
    try {
      await context.read<ElevageRepository>().deleteSuivi(suivi.id!);
      _suivisKey.currentState?.reload();
    } catch (e) {
      if (mounted) showMessage(context, messageErreur(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repository = context.read<ElevageRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_animal.titre),
        actions: [
          IconButton(
            tooltip: 'Modifier',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _edit,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-animal',
        onPressed: _addSuivi,
        icon: const Icon(Icons.add),
        label: const Text('Suivi sanitaire'),
      ),
      body: AsyncView<List<SuiviSanitaire>>(
        key: _suivisKey,
        load: () => repository.suivis(_animal.id!),
        builder: (context, suivis) => ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Info('Espèce', _animal.espece),
                    if (_animal.race.isNotEmpty) _Info('Race', _animal.race),
                    if (_animal.identifiant.isNotEmpty)
                      _Info('Identifiant', _animal.identifiant),
                    _Info(
                      'Effectif',
                      _animal.estLot
                          ? '${_animal.effectif} (lot)'
                          : '1 (animal seul)',
                    ),
                    if (_animal.dateNaissance != null)
                      _Info('Naissance', formatDate(_animal.dateNaissance)),
                    if (_animal.notes.isNotEmpty) _Info('Notes', _animal.notes),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
              child: Text(
                'Suivi sanitaire',
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (suivis.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Aucune intervention enregistrée.'),
              ),
            for (final suivi in suivis)
              Card(
                child: ListTile(
                  leading: Icon(switch (suivi.type) {
                    TypeSuivi.vaccination => Icons.vaccines,
                    TypeSuivi.traitement => Icons.medication_outlined,
                    TypeSuivi.visite => Icons.medical_services_outlined,
                  }),
                  title: Text(
                    '${suivi.type.label} — ${formatDate(suivi.date)}',
                  ),
                  subtitle: Text(
                    [
                      if (suivi.description.isNotEmpty) suivi.description,
                      if (suivi.prochaineEcheance != null)
                        'Prochaine échéance : '
                            '${formatDate(suivi.prochaineEcheance)}',
                    ].join('\n'),
                  ),
                  isThreeLine:
                      suivi.description.isNotEmpty &&
                      suivi.prochaineEcheance != null,
                  trailing: IconButton(
                    tooltip: 'Supprimer',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteSuivi(suivi),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
