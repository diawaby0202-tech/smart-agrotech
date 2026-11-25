import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'historique_recoltes_screen.dart';
import 'parcelle.dart';
import 'parcelle_repository.dart';

const _moisNoms = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

const _joursNoms = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

class CalendrierRecoltesScreen extends StatefulWidget {
  const CalendrierRecoltesScreen({super.key});

  @override
  State<CalendrierRecoltesScreen> createState() =>
      _CalendrierRecoltesScreenState();
}

class _CalendrierRecoltesScreenState extends State<CalendrierRecoltesScreen> {
  late DateTime _mois = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime _selection = DateTime.now();

  void _changerMois(int decalage) {
    setState(() {
      _mois = DateTime(_mois.year, _mois.month + decalage);
      _selection = DateTime(_mois.year, _mois.month);
    });
  }

  bool _memeJour(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendrier des récoltes')),
      body: SafeArea(
        child: AsyncView<List<Parcelle>>(
          load: context.read<ParcelleRepository>().calendrier,
          builder: (context, parcelles) {
            final recoltesParJour = <DateTime, List<Parcelle>>{};
            for (final parcelle in parcelles) {
              final date = parcelle.dateRecoltePrevue;
              if (date == null) continue;
              final jour = DateTime(date.year, date.month, date.day);
              recoltesParJour.putIfAbsent(jour, () => []).add(parcelle);
            }
            final recoltesSelection = recoltesParJour[_selection] ?? [];
            final premierJour = DateTime(_mois.year, _mois.month, 1);
            final decalage = premierJour.weekday - 1;
            final nombreJours = DateTime(_mois.year, _mois.month + 1, 0).day;

            final totalCases = ((decalage + nombreJours + 6) ~/ 7) * 7;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    IconButton(
                      key: const Key('calendrier-mois-precedent'),
                      tooltip: 'Mois précédent',
                      onPressed: () => _changerMois(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        '${_moisNoms[_mois.month - 1]} ${_mois.year}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      key: const Key('calendrier-mois-suivant'),
                      tooltip: 'Mois suivant',
                      onPressed: () => _changerMois(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final jour in _joursNoms)
                      Expanded(
                        child: Center(
                          child: Text(
                            jour,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  key: const Key('calendrier-grille'),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                        childAspectRatio: 0.9,
                      ),
                  itemCount: totalCases,
                  itemBuilder: (context, index) {
                    if (index < decalage) return const SizedBox.shrink();
                    final date = DateTime(
                      _mois.year,
                      _mois.month,
                      index - decalage + 1,
                    );
                    final count = recoltesParJour[date]?.length ?? 0;
                    final selected = _memeJour(date, _selection);
                    return Material(
                      color: selected
                          ? Couleurs.vert700
                          : count > 0
                          ? Couleurs.vert50
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        key: Key('calendrier-jour-${date.day}'),
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setState(() => _selection = date),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                color: selected ? Colors.white : Couleurs.encre,
                                fontWeight: count > 0
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                            ),
                            if (count > 0)
                              Text(
                                '$count',
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : Couleurs.vert700,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  formatDateLongue(_selection),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (recoltesSelection.isEmpty)
                  const Text('Aucune récolte prévue ce jour.')
                else
                  for (final parcelle in recoltesSelection)
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.agriculture_outlined,
                          color: Couleurs.vert700,
                        ),
                        title: Text('${parcelle.culture} — ${parcelle.nom}'),
                        subtitle: Text(
                          [
                            if (parcelle.localisation.isNotEmpty)
                              parcelle.localisation,
                            if (parcelle.dateRecoltePrevue != null)
                              'Récolte prévue le '
                                  '${formatDateLongue(parcelle.dateRecoltePrevue)}',
                          ].where((texte) => texte.isNotEmpty).join(' · '),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: parcelle.id == null
                            ? null
                            : () => Navigator.of(context).push<void>(
                                MaterialPageRoute(
                                  builder: (_) => HistoriqueRecoltesScreen(
                                    parcelle: parcelle,
                                  ),
                                ),
                              ),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}
