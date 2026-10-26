import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design.dart';
import '../../core/format.dart';
import '../../core/notification_service.dart';
import '../../core/theme.dart';
import '../../core/visuels.dart';
import '../../core/widgets.dart';
import '../home/menu.dart';
import 'alertes_models.dart';
import 'alertes_repository.dart';

/// Module Météo et alertes, sur le modèle de la page « Alertes météo &
/// environnementales » du site.
class MeteoScreen extends StatefulWidget {
  const MeteoScreen({super.key});

  @override
  State<MeteoScreen> createState() => _MeteoScreenState();
}

typedef _Donnees = ({Meteo? meteo, String? erreurMeteo, List<Alerte> alertes});

class _MeteoScreenState extends State<MeteoScreen> {
  final _key = GlobalKey<AsyncViewState<_Donnees>>();
  String _ville = villesSenegal.first;

  void _reload() => _key.currentState?.reload();

  /// La météo peut être indisponible sans empêcher d'afficher les alertes.
  Future<_Donnees> _load() async {
    final repository = context.read<AlertesRepository>();
    final rappels = context.read<RappelService>();
    Meteo? meteo;
    String? erreurMeteo;
    try {
      meteo = await repository.meteo(_ville);
    } catch (e) {
      erreurMeteo = messageErreur(e);
    }
    // Génère les alertes du jour et notifie les nouvelles.
    await rappels.synchroniser();
    final alertes = await repository.alertes();
    return (meteo: meteo, erreurMeteo: erreurMeteo, alertes: alertes);
  }

  Future<void> _action(Future<void> Function(AlertesRepository) action) async {
    try {
      await action(context.read<AlertesRepository>());
      _reload();
    } catch (e) {
      if (mounted) showMessage(context, messageErreur(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const BarreMarque(),
      body: SafeArea(
        child: AsyncView<_Donnees>(
          key: _key,
          load: _load,
          builder: (context, donnees) {
            final nonLues = donnees.alertes.where((a) => !a.lue).length;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                const BandeauModule(
                  icone: '⛅',
                  titre: 'Alertes météo & environnementales',
                  texte:
                      'La météo de votre zone et des alertes précoces pour '
                      'protéger vos activités.',
                ),
                const SizedBox(height: 16),
                _CarteMeteo(
                  ville: _ville,
                  meteo: donnees.meteo,
                  erreur: donnees.erreurMeteo,
                  onVille: (ville) {
                    setState(() => _ville = ville);
                    _reload();
                  },
                ),
                for (final risque in donnees.meteo?.risques ?? <RisqueMeteo>[])
                  _CarteAlerte(
                    icone: '⛈️',
                    titre: risque.titre,
                    message: risque.message,
                    niveau: risque.niveau,
                  ),
                const SizedBox(height: 20),
                Text(
                  '🔔 Mes alertes ($nonLues non lue${nonLues > 1 ? 's' : ''})',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    BoutonCarte('Actualiser mes alertes', onPressed: _reload),
                    BoutonCarte(
                      'Tout marquer comme lu',
                      onPressed: () => _action((r) => r.toutMarquerLu()),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (donnees.alertes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Aucune alerte pour le moment.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (final alerte in donnees.alertes)
                  _CarteAlerte(
                    icone: emojiTypeAlerte(alerte.type.apiValue),
                    titre: alerte.titre,
                    message: alerte.message,
                    niveau: alerte.niveau,
                    details: [
                      if (alerte.zone.isNotEmpty) '📍 ${alerte.zone}',
                      '🕒 ${formatDateCourte(alerte.dateCreation)}, '
                          '${alerte.dateCreation.hour.toString().padLeft(2, '0')}:'
                          '${alerte.dateCreation.minute.toString().padLeft(2, '0')}',
                    ].join(' · '),
                    nonLue: !alerte.lue,
                    onLue: alerte.lue
                        ? null
                        : () => _action((r) => r.marquerLue(alerte.id)),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CarteMeteo extends StatelessWidget {
  const _CarteMeteo({
    required this.ville,
    required this.meteo,
    required this.erreur,
    required this.onVille,
  });

  final String ville;
  final Meteo? meteo;
  final String? erreur;
  final ValueChanged<String> onVille;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const blanc = Colors.white;
    final jours = meteo?.previsions ?? const <JourMeteo>[];
    final aujourdhui = jours.isEmpty ? null : jours.first;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: Couleurs.degradeMeteo,
        borderRadius: BorderRadius.circular(20),
        boxShadow: ombreCarte,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📍 $ville, Sénégal',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: blanc,
                      ),
                    ),
                    Text(
                      'Prévisions sur 5 jours',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: blanc.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              if (aujourdhui != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${aujourdhui.tempMax.round()}°',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: blanc,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${iconeMeteo(aujourdhui.description)} '
                      '${aujourdhui.description}',
                      style: theme.textTheme.bodySmall?.copyWith(color: blanc),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: const Key('meteo-ville'),
                value: ville,
                isExpanded: true,
                items: [
                  for (final v in villesSenegal)
                    DropdownMenuItem(value: v, child: Text(v)),
                ],
                onChanged: (v) => onVille(v!),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (erreur != null)
            Text(
              '☁️  $erreur',
              style: theme.textTheme.bodyLarge?.copyWith(color: blanc),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final jour in jours)
                  Container(
                    width: 96,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          nomJour(jour.date),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: blanc,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          iconeMeteo(jour.description),
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${jour.tempMax.round()}° / ${jour.tempMin.round()}°',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: blanc,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (jour.pluieMm > 0 || jour.ventKmh >= 30)
                          Text(
                            jour.pluieMm > 0
                                ? '${formatNombre(jour.pluieMm)} mm'
                                : 'Vent : ${jour.ventKmh} km/h',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: blanc,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Couleurs et libellés des niveaux d'alerte, comme sur le site.
({String libelle, Color fond, Color bord, Color badge}) _styleNiveau(
  NiveauAlerte niveau,
) => switch (niveau) {
  NiveauAlerte.info => (
    libelle: 'Information',
    fond: Couleurs.infoClair,
    bord: Couleurs.info,
    badge: Couleurs.vert600,
  ),
  NiveauAlerte.attention => (
    libelle: 'Vigilance',
    fond: Couleurs.or100,
    bord: Couleurs.or500,
    badge: Couleurs.info,
  ),
  NiveauAlerte.danger => (
    libelle: 'Risque',
    fond: Couleurs.dangerClair,
    bord: Couleurs.danger,
    badge: Couleurs.danger,
  ),
};

class _CarteAlerte extends StatelessWidget {
  const _CarteAlerte({
    required this.icone,
    required this.titre,
    required this.message,
    required this.niveau,
    this.details,
    this.nonLue = false,
    this.onLue,
  });

  final String icone;
  final String titre;
  final String message;
  final NiveauAlerte niveau;
  final String? details;
  final bool nonLue;
  final VoidCallback? onLue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _styleNiveau(niveau);

    // Une bordure arrondie doit être d'une seule couleur : le liseré gauche,
    // plus foncé, est donc une bande dessinée à part.
    return Container(
      margin: const EdgeInsets.only(top: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: style.fond,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: style.bord.withValues(alpha: 0.3)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: style.bord),
            Expanded(child: _contenu(theme, style.libelle, style.badge)),
          ],
        ),
      ),
    );
  }

  Widget _contenu(ThemeData theme, String libelle, Color badge) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(icone, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titre,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: nonLue ? FontWeight.w800 : FontWeight.w600,
                    color: Couleurs.encre,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Etiquette(libelle, fond: badge),
            ],
          ),
          if (details != null) ...[
            const SizedBox(height: 6),
            Text(
              details!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Couleurs.ardoise500,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text('💡 $message', style: theme.textTheme.bodyMedium),
          if (onLue != null) ...[
            const SizedBox(height: 10),
            BoutonCarte('Marquer comme lue', onPressed: onLue!),
          ],
        ],
      ),
    );
  }
}
