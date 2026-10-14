import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/widgets.dart';
import 'annonce.dart';
import 'annonce_form_screen.dart';

/// Détail d'une annonce : contact du vendeur (RF-18) ou gestion par son
/// propriétaire (RF-19). Renvoie `true` si l'annonce a été modifiée.
class AnnonceDetailScreen extends StatelessWidget {
  const AnnonceDetailScreen({super.key, required this.annonce});

  final Annonce annonce;

  Future<void> _contacter(BuildContext context, String scheme) async {
    final uri = Uri(scheme: scheme, path: annonce.vendeurTelephone);
    var ouvert = false;
    try {
      ouvert = await launchUrl(uri);
    } catch (_) {
      ouvert = false;
    }
    if (ouvert || !context.mounted) return;
    // Pas d'application téléphone (tablette, émulateur) : on copie le numéro.
    await Clipboard.setData(ClipboardData(text: annonce.vendeurTelephone));
    if (context.mounted) {
      showMessage(context, 'Numéro copié : ${annonce.vendeurTelephone}');
    }
  }

  Future<void> _modifier(BuildContext context) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AnnonceFormScreen(annonce: annonce)),
    );
    if (changed == true && context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aUnTelephone = annonce.vendeurTelephone.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Annonce'),
        actions: [
          if (annonce.estProprietaire)
            IconButton(
              tooltip: 'Modifier',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _modifier(context),
            ),
        ],
      ),
      body: ListView(
        children: [
          if (annonce.photoUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                annonce.photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(annonce.titre, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  formatPrix(annonce.prix),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Chip(label: Text(annonce.categorie.label)),
                    if (annonce.quantite.isNotEmpty)
                      Chip(label: Text(annonce.quantite)),
                    if (annonce.zone.isNotEmpty)
                      Chip(
                        avatar: const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                        ),
                        label: Text(annonce.zone),
                      ),
                    if (annonce.statut != StatutAnnonce.disponible)
                      Chip(label: Text(annonce.statut.label)),
                  ],
                ),
                if (annonce.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(annonce.description, style: theme.textTheme.bodyLarge),
                ],
                const SizedBox(height: 24),
                Text('Vendeur', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(
                    annonce.estProprietaire
                        ? '${annonce.vendeurNom} (vous)'
                        : annonce.vendeurNom,
                  ),
                  subtitle: Text(
                    [
                      if (aUnTelephone) annonce.vendeurTelephone,
                      if (annonce.dateCreation != null)
                        'Publiée le ${formatDate(annonce.dateCreation)}',
                    ].join(' · '),
                  ),
                ),
                if (!annonce.estProprietaire && aUnTelephone) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    key: const Key('annonce-appeler'),
                    onPressed: () => _contacter(context, 'tel'),
                    icon: const Icon(Icons.call),
                    label: const Text('Appeler le vendeur'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => _contacter(context, 'sms'),
                    icon: const Icon(Icons.sms_outlined),
                    label: const Text('Envoyer un SMS'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
