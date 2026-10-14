import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/widgets.dart';
import 'parcelle.dart';
import 'parcelle_form_screen.dart';
import 'parcelle_repository.dart';

/// Module Cultures : liste des parcelles et calendrier des récoltes.
class CulturesScreen extends StatefulWidget {
  const CulturesScreen({super.key});

  @override
  State<CulturesScreen> createState() => _CulturesScreenState();
}

class _CulturesScreenState extends State<CulturesScreen> {
  final _listKey = GlobalKey<AsyncViewState<List<Parcelle>>>();
  final _calendarKey = GlobalKey<AsyncViewState<List<Parcelle>>>();

  void _reload() {
    _listKey.currentState?.reload();
    _calendarKey.currentState?.reload();
  }

  Future<void> _openForm([Parcelle? parcelle]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ParcelleFormScreen(parcelle: parcelle)),
    );
    if (changed == true) _reload();
  }

  /// Passe rapidement une parcelle à une autre étape (RF-07).
  Future<void> _changerStatut(Parcelle parcelle, StatutParcelle statut) async {
    try {
      await context.read<ParcelleRepository>().update(
        parcelle.copyWith(statut: statut),
      );
      _reload();
    } catch (e) {
      if (mounted) showMessage(context, messageErreur(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<ParcelleRepository>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cultures'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Parcelles'),
              Tab(text: 'Calendrier'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openForm,
          icon: const Icon(Icons.add),
          label: const Text('Parcelle'),
        ),
        body: TabBarView(
          children: [
            AsyncView<List<Parcelle>>(
              key: _listKey,
              load: repository.list,
              builder: (context, parcelles) => parcelles.isEmpty
                  ? const MessageView(
                      icon: Icons.grass,
                      message:
                          'Aucune parcelle.\nAjoutez votre première parcelle.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                      itemCount: parcelles.length,
                      itemBuilder: (context, index) => _ParcelleCard(
                        parcelle: parcelles[index],
                        onTap: () => _openForm(parcelles[index]),
                        onStatut: (statut) =>
                            _changerStatut(parcelles[index], statut),
                      ),
                    ),
            ),
            AsyncView<List<Parcelle>>(
              key: _calendarKey,
              load: repository.calendrier,
              builder: (context, parcelles) => parcelles.isEmpty
                  ? const MessageView(
                      icon: Icons.event_available,
                      message:
                          'Aucune récolte prévue.\nRenseignez une date de '
                          'récolte sur vos parcelles.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                      itemCount: parcelles.length,
                      itemBuilder: (context, index) => _RecolteTile(
                        parcelle: parcelles[index],
                        onTap: () => _openForm(parcelles[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParcelleCard extends StatelessWidget {
  const _ParcelleCard({
    required this.parcelle,
    required this.onTap,
    required this.onStatut,
  });

  final Parcelle parcelle;
  final VoidCallback onTap;
  final ValueChanged<StatutParcelle> onStatut;

  @override
  Widget build(BuildContext context) {
    final details = [
      '${formatNombre(parcelle.superficie)} ha',
      if (parcelle.localisation.isNotEmpty) parcelle.localisation,
      if (parcelle.dateSemis != null)
        'Semis : ${formatDate(parcelle.dateSemis)}',
    ].join(' · ');

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(child: Icon(Icons.grass)),
        title: Text('${parcelle.nom} — ${parcelle.culture}'),
        subtitle: Text(details),
        trailing: PopupMenuButton<StatutParcelle>(
          tooltip: 'Changer l\'étape',
          initialValue: parcelle.statut,
          onSelected: onStatut,
          itemBuilder: (context) => [
            for (final statut in StatutParcelle.values)
              PopupMenuItem(value: statut, child: Text(statut.label)),
          ],
          child: Chip(label: Text(parcelle.statut.label)),
        ),
      ),
    );
  }
}

class _RecolteTile extends StatelessWidget {
  const _RecolteTile({required this.parcelle, required this.onTap});

  final Parcelle parcelle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = parcelle.dateRecoltePrevue!;
    final enRetard = joursRestants(date) < 0;
    final color = enRetard ? Theme.of(context).colorScheme.error : null;

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.event, color: color),
        title: Text('${parcelle.culture} — ${parcelle.nom}'),
        subtitle: Text('Récolte prévue le ${formatDate(date)}'),
        trailing: Text(formatEcheance(date), style: TextStyle(color: color)),
      ),
    );
  }
}
