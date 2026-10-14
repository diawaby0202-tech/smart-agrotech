import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/notification_service.dart';
import '../../core/widgets.dart';
import 'alertes_models.dart';
import 'alertes_repository.dart';

/// Module Météo et alertes : prévisions par ville et historique des alertes.
class MeteoScreen extends StatefulWidget {
  const MeteoScreen({super.key});

  @override
  State<MeteoScreen> createState() => _MeteoScreenState();
}

class _MeteoScreenState extends State<MeteoScreen> {
  final _meteoKey = GlobalKey<AsyncViewState<Meteo>>();
  final _alertesKey = GlobalKey<AsyncViewState<List<Alerte>>>();
  String _ville = villesSenegal.first;

  /// Génère les alertes du jour, notifie les nouvelles, puis charge la liste.
  Future<List<Alerte>> _loadAlertes() async {
    await context.read<RappelService>().synchroniser();
    if (!mounted) return const [];
    return context.read<AlertesRepository>().alertes();
  }

  Future<void> _marquerLue(Alerte alerte) async {
    if (alerte.lue) return;
    try {
      await context.read<AlertesRepository>().marquerLue(alerte.id);
      _alertesKey.currentState?.reload();
    } catch (e) {
      if (mounted) showMessage(context, messageErreur(e));
    }
  }

  Future<void> _toutMarquerLu() async {
    try {
      await context.read<AlertesRepository>().toutMarquerLu();
      _alertesKey.currentState?.reload();
    } catch (e) {
      if (mounted) showMessage(context, messageErreur(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<AlertesRepository>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Météo et alertes'),
          actions: [
            IconButton(
              tooltip: 'Tout marquer comme lu',
              icon: const Icon(Icons.done_all),
              onPressed: _toutMarquerLu,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Prévisions'),
              Tab(text: 'Alertes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: DropdownButtonFormField<String>(
                    initialValue: _ville,
                    decoration: const InputDecoration(
                      labelText: 'Ville',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    items: [
                      for (final ville in villesSenegal)
                        DropdownMenuItem(value: ville, child: Text(ville)),
                    ],
                    onChanged: (ville) {
                      setState(() => _ville = ville!);
                      _meteoKey.currentState?.reload();
                    },
                  ),
                ),
                Expanded(
                  child: AsyncView<Meteo>(
                    key: _meteoKey,
                    load: () => repository.meteo(_ville),
                    builder: (context, meteo) => _MeteoList(meteo: meteo),
                  ),
                ),
              ],
            ),
            AsyncView<List<Alerte>>(
              key: _alertesKey,
              load: _loadAlertes,
              builder: (context, alertes) => alertes.isEmpty
                  ? const MessageView(
                      icon: Icons.notifications_none,
                      message: 'Aucune alerte pour le moment.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: alertes.length,
                      itemBuilder: (context, index) => _AlerteCard(
                        alerte: alertes[index],
                        onTap: () => _marquerLue(alertes[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _couleurNiveau(BuildContext context, NiveauAlerte niveau) {
  final scheme = Theme.of(context).colorScheme;
  return switch (niveau) {
    NiveauAlerte.info => scheme.primary,
    NiveauAlerte.attention => Colors.orange.shade800,
    NiveauAlerte.danger => scheme.error,
  };
}

IconData _iconeMeteo(JourMeteo jour) {
  if (jour.pluieMm >= 1) return Icons.water_drop;
  final description = jour.description.toLowerCase();
  if (description.contains('nuage') || description.contains('couvert')) {
    return Icons.cloud;
  }
  return Icons.wb_sunny;
}

class _MeteoList extends StatelessWidget {
  const _MeteoList({required this.meteo});

  final Meteo meteo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (meteo.previsions.isEmpty) {
      return const MessageView(
        icon: Icons.cloud_off,
        message: 'Aucune prévision disponible pour cette ville.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final risque in meteo.risques)
          Card(
            color: _couleurNiveau(
              context,
              risque.niveau,
            ).withValues(alpha: 0.12),
            child: ListTile(
              leading: Icon(
                Icons.warning_amber_rounded,
                color: _couleurNiveau(context, risque.niveau),
              ),
              title: Text(risque.titre),
              subtitle: Text(risque.message),
            ),
          ),
        for (final jour in meteo.previsions)
          Card(
            child: ListTile(
              leading: Icon(
                _iconeMeteo(jour),
                color: theme.colorScheme.primary,
              ),
              title: Text(
                '${formatDate(jour.date)} — '
                '${formatNombre(jour.tempMin)}° / ${formatNombre(jour.tempMax)}°C',
              ),
              subtitle: Text(
                [
                  if (jour.description.isNotEmpty) jour.description,
                  'Pluie : ${formatNombre(jour.pluieMm)} mm',
                  'Vent : ${jour.ventKmh} km/h',
                ].join(' · '),
              ),
            ),
          ),
      ],
    );
  }
}

class _AlerteCard extends StatelessWidget {
  const _AlerteCard({required this.alerte, required this.onTap});

  final Alerte alerte;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _couleurNiveau(context, alerte.niveau);
    final icon = switch (alerte.type) {
      TypeAlerte.meteo => Icons.thunderstorm_outlined,
      TypeAlerte.vaccination => Icons.vaccines,
      TypeAlerte.culture => Icons.grass,
      TypeAlerte.systeme => Icons.info_outline,
    };

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(
          alerte.titre,
          style: TextStyle(
            fontWeight: alerte.lue ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${alerte.message}\n'
          '${alerte.niveau.label} · ${formatDate(alerte.dateCreation)}',
        ),
        isThreeLine: true,
        trailing: alerte.lue
            ? null
            : Icon(Icons.circle, size: 12, color: color),
      ),
    );
  }
}
