import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/design.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../auth/auth_provider.dart';
import '../auth/user.dart';
import 'annonce.dart';
import 'commande.dart';
import 'commande_repository.dart';

class AchatAnnonceScreen extends StatefulWidget {
  const AchatAnnonceScreen({super.key, required this.annonce});

  final Annonce annonce;

  @override
  State<AchatAnnonceScreen> createState() => _AchatAnnonceScreenState();
}

class _AchatAnnonceScreenState extends State<AchatAnnonceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantite = TextEditingController(text: '1');
  MoyenPaiement _moyen = MoyenPaiement.wave;
  Commande? _commande;
  bool _chargement = false;
  String? _erreur;

  @override
  void dispose() {
    _quantite.dispose();
    super.dispose();
  }

  double get _quantiteSaisie =>
      double.tryParse(_quantite.text.trim().replaceAll(',', '.')) ?? 0;

  Future<void> _commander() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final commande = await context.read<CommandeRepository>().create(
        annonceId: widget.annonce.id!,
        quantite: _quantiteSaisie,
        moyenPaiement: _moyen,
      );
      if (mounted) setState(() => _commande = commande);
    } catch (e) {
      if (mounted) setState(() => _erreur = messageErreur(e));
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _signalerPaiement() async {
    final commande = _commande;
    if (commande == null) return;
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final updated = await context
          .read<CommandeRepository>()
          .signalerPaiement(commande.id);
      if (mounted) setState(() => _commande = updated);
    } catch (e) {
      if (mounted) setState(() => _erreur = messageErreur(e));
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final annonce = widget.annonce;
    final commande = _commande;
    final unite = annonce.unite?.label ?? '';
    final montant = annonce.prix * _quantiteSaisie;

    return Scaffold(
      appBar: AppBar(title: const Text('Commander')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(annonce.titre, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            '${formatPrixParUnite(annonce.prix, unite)} · '
            'Stock : ${formatNombre(annonce.stock ?? 0)} $unite',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (commande == null) ...[
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const Key('commande-quantite'),
                    controller: _quantite,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Quantité',
                      suffixText: unite,
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      final q = double.tryParse(
                        (value ?? '').trim().replaceAll(',', '.'),
                      );
                      if (q == null || q <= 0) {
                        return 'Indiquez une quantité positive';
                      }
                      if (q > (annonce.stock ?? 0)) {
                        return 'Stock disponible insuffisant';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Moyen de paiement', style: Theme.of(context).textTheme.titleMedium),
                  RadioGroup<MoyenPaiement>(
                    groupValue: _moyen,
                    onChanged: (value) {
                      if (value != null) setState(() => _moyen = value);
                    },
                    child: Column(
                      children: const [
                        RadioListTile(
                          value: MoyenPaiement.wave,
                          title: Text('Wave'),
                          secondary: Icon(Icons.water_drop_outlined),
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile(
                          value: MoyenPaiement.orangeMoney,
                          title: Text('Orange Money'),
                          secondary: Icon(Icons.phone_android),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Expanded(child: Text('Total à transférer')),
                          Text(
                            formatPrix(montant.round()),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Couleurs.vert700,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_erreur != null)
                    Text(
                      _erreur!,
                      style: const TextStyle(color: Couleurs.danger),
                    ),
                  const SizedBox(height: 8),
                  SubmitButton(
                    key: const Key('commande-creer'),
                    label: 'Continuer vers le paiement',
                    loading: _chargement,
                    onPressed: _commander,
                  ),
                ],
              ),
            ),
          ] else ...[
            _InstructionsPaiement(
              commande: commande,
              onSignaler: _signalerPaiement,
              chargement: _chargement,
              erreur: _erreur,
            ),
          ],
        ],
      ),
    );
  }
}

class _InstructionsPaiement extends StatelessWidget {
  const _InstructionsPaiement({
    required this.commande,
    required this.onSignaler,
    required this.chargement,
    required this.erreur,
  });

  final Commande commande;
  final VoidCallback onSignaler;
  final bool chargement;
  final String? erreur;

  @override
  Widget build(BuildContext context) {
    final wave = commande.moyenPaiement == MoyenPaiement.wave;
    final provider = wave ? 'Wave' : 'Orange Money';
    final qrPayload = jsonEncode({
      'application': 'SmartAgroTech',
      'type': 'instructions_transfert_manuel',
      'operateur': provider,
      'numero': commande.telephonePaiement,
      'montant_fcfa': commande.total,
      'reference': 'SAT-${commande.id}',
    });
    final signale = commande.statut == StatutCommande.paiementSignale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: Couleurs.vert50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Commande #${commande.id}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('${commande.annonceTitre} · ${commande.quantite} ${commande.annonceUnite}'),
                Text('Total : ${formatPrix(commande.total)}'),
                Text('Paiement : $provider'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Transfert manuel vers le numéro du vendeur',
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  formatTelephone(commande.telephonePaiement),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Couleurs.vert700,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(provider),
                const SizedBox(height: 12),
                QrImageView(
                  data: qrPayload,
                  version: QrVersions.auto,
                  size: 190,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ce QR contient les instructions et la référence. '
                  'Ce n’est pas un QR de paiement opérateur : vérifiez le '
                  'numéro et le montant dans votre application mobile money.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (erreur != null)
          Text(erreur!, style: const TextStyle(color: Couleurs.danger)),
        if (signale)
          Encadre(
            icone: Icons.hourglass_top,
            texte:
                'Paiement signalé. La commande reste en attente jusqu’à ce '
                'que le vendeur vérifie le transfert.',
            fond: Couleurs.or100,
            couleur: Couleurs.or600,
          )
        else
          SubmitButton(
            key: const Key('commande-signaler-paiement'),
            label: 'J’ai effectué le transfert',
            loading: chargement,
            onPressed: onSignaler,
          ),
      ],
    );
  }
}

class CommandesScreen extends StatelessWidget {
  const CommandesScreen({super.key});

  Future<void> _confirmer(
    BuildContext context,
    Commande commande,
    AsyncViewState<List<Commande>> state,
  ) async {
    try {
      await context.read<CommandeRepository>().confirmer(commande.id);
      await state.reload();
    } catch (e) {
      if (context.mounted) showMessage(context, messageErreur(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().user?.role;
    final vendeur = role != UserRole.acheteur;
    return Scaffold(
      appBar: AppBar(title: Text(vendeur ? 'Commandes reçues' : 'Mes commandes')),
      body: AsyncView<List<Commande>>(
        load: () => context.read<CommandeRepository>().list(),
        builder: (context, commandes) {
          if (commandes.isEmpty) {
            return ListView(
              children: [
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Aucune commande pour le moment.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final commande in commandes)
                Card(
                  key: Key('commande-${commande.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          commande.annonceTitre,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${vendeur ? commande.acheteurNom : commande.vendeurNom} · '
                          '${commande.quantite} ${commande.annonceUnite}',
                        ),
                        Text(
                          '${formatPrix(commande.total)} · '
                          '${commande.moyenPaiement == MoyenPaiement.wave ? 'Wave' : 'Orange Money'}',
                        ),
                        const SizedBox(height: 6),
                        Chip(label: Text(commande.statut.label)),
                        if (vendeur &&
                            commande.statut == StatutCommande.paiementSignale)
                          FilledButton.icon(
                            key: Key('commande-confirmer-${commande.id}'),
                            onPressed: () =>
                                _confirmer(context, commande, _state(context)),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Confirmer après vérification'),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  AsyncViewState<List<Commande>> _state(BuildContext context) =>
      context.findAncestorStateOfType<AsyncViewState<List<Commande>>>()!;
}
