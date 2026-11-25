import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'annonce_moderation.dart';
import 'annonce_moderation_repository.dart';

class AnnonceModerationScreen extends StatefulWidget {
  const AnnonceModerationScreen({super.key});

  @override
  State<AnnonceModerationScreen> createState() =>
      _AnnonceModerationScreenState();
}

class _AnnonceModerationScreenState extends State<AnnonceModerationScreen> {
  final _listKey = GlobalKey<AsyncViewState<List<AnnonceModeration>>>();
  final _recherche = TextEditingController();
  ModerationAnnonce? _filtre;
  String _rechercheEnvoyee = '';

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  Future<List<AnnonceModeration>> _load() =>
      context.read<AnnonceModerationRepository>().list(
        moderation: _filtre,
        recherche: _rechercheEnvoyee,
      );

  void _reload() => _listKey.currentState?.reload();

  Future<void> _changerModeration(AnnonceModeration annonce) async {
    final repository = context.read<AnnonceModerationRepository>();
    try {
      if (annonce.moderation == ModerationAnnonce.approuvee) {
        await repository.masquer(annonce.id);
      } else {
        await repository.restaurer(annonce.id);
      }
      _reload();
    } catch (e) {
      if (mounted) showMessage(context, messageErreur(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modération des annonces')),
      body: SafeArea(
        child: AsyncView<List<AnnonceModeration>>(
          key: _listKey,
          load: _load,
          builder: (context, annonces) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                key: const Key('moderation-recherche'),
                controller: _recherche,
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  setState(() => _rechercheEnvoyee = value.trim());
                  _reload();
                },
                decoration: InputDecoration(
                  labelText: 'Rechercher une annonce',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: 'Rechercher',
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () {
                      setState(
                        () => _rechercheEnvoyee = _recherche.text.trim(),
                      );
                      _reload();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Toutes'),
                    selected: _filtre == null,
                    onSelected: (_) {
                      setState(() => _filtre = null);
                      _reload();
                    },
                  ),
                  for (final statut in ModerationAnnonce.values)
                    ChoiceChip(
                      label: Text(statut.label),
                      selected: _filtre == statut,
                      onSelected: (_) {
                        setState(() => _filtre = statut);
                        _reload();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (annonces.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'Aucune annonce à afficher.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final annonce in annonces)
                Card(
                  key: Key('annonce-moderation-${annonce.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                annonce.titre,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Chip(label: Text(annonce.moderation.label)),
                          ],
                        ),
                        Text(
                          '${annonce.categorie.label} · '
                          '${formatPrix(annonce.prix)}',
                        ),
                        if (annonce.zone.isNotEmpty)
                          Text('Zone : ${annonce.zone}'),
                        if (annonce.vendeurEmail.isNotEmpty)
                          Text('Vendeur : ${annonce.vendeurEmail}'),
                        if (annonce.dateCreation != null)
                          Text(
                            'Publiée le ${formatDateLongue(annonce.dateCreation)}',
                          ),
                        if (annonce.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(annonce.description),
                        ],
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: () => _changerModeration(annonce),
                            icon: Icon(
                              annonce.moderation ==
                                      ModerationAnnonce.approuvee
                                  ? Icons.visibility_off_outlined
                                  : Icons.restore,
                            ),
                            label: Text(
                              annonce.moderation ==
                                      ModerationAnnonce.approuvee
                                  ? 'Masquer'
                                  : 'Restaurer',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Couleurs.vert700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
