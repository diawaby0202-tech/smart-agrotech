import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/design.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'auth_provider.dart';
import 'user.dart';
import 'validators.dart';

/// Page « Mon profil » (RF-05), sur le modèle de celle du site : les
/// informations du compte, puis le formulaire pour les modifier.
class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late final User _initial = context.read<AuthProvider>().user!;
  late final _prenom = TextEditingController(text: _initial.prenom);
  late final _nom = TextEditingController(text: _initial.nom);
  late final _telephone = TextEditingController(text: _initial.telephone);

  bool _loading = false;
  String? _succes;
  String? _erreur;

  @override
  void dispose() {
    _prenom.dispose();
    _nom.dispose();
    _telephone.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    setState(() {
      _succes = null;
      _erreur = null;
    });
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().updateProfile(
        prenom: _prenom.text.trim(),
        nom: _nom.text.trim(),
        telephone: _telephone.text.trim(),
      );
      if (mounted) setState(() => _succes = 'Profil mis à jour avec succès.');
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static String _libelleStatut(String statut) => switch (statut) {
    'valide' => 'Validé',
    'en_attente' => 'En attente de validation',
    'refuse' => 'Refusé',
    'suspendu' => 'Suspendu',
    _ => '—',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const Scaffold();
    final valide = user.statut == 'valide';

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: FormBody(
        children: [
          Text(
            'Consultez et modifiez vos informations personnelles.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Couleurs.ardoise500,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Informations', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _Info('Rôle', Text(user.role.label)),
                  _Info(
                    'Statut du compte',
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Etiquette(
                        _libelleStatut(user.statut),
                        fond: valide ? Couleurs.vert100 : Couleurs.or100,
                        couleur: valide ? Couleurs.vert700 : Couleurs.or600,
                      ),
                    ),
                  ),
                  _Info('E-mail', Text(user.email)),
                  _Info(
                    'Membre depuis',
                    Text(
                      user.dateInscription == null
                          ? '—'
                          : formatDate(user.dateInscription!.toLocal()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (user.role == UserRole.admin) ...[
            const SizedBox(height: 8),
            const Encadre(
              icone: '🛡️',
              texte:
                  'Compte administrateur : la gestion des utilisateurs, la '
                  'modération et les statistiques se font sur le site web.',
              fond: Couleurs.infoClair,
              couleur: Couleurs.info,
            ),
          ],
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Modifier mes informations',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    if (_succes != null) ...[
                      Encadre(
                        icone: '✅',
                        texte: _succes!,
                        fond: Couleurs.vert50,
                        couleur: Couleurs.vert700,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_erreur != null) ...[
                      Encadre(
                        icone: '⚠️',
                        texte: _erreur!,
                        fond: Couleurs.dangerClair,
                        couleur: Couleurs.danger,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      key: const Key('profil-prenom'),
                      controller: _prenom,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Prénom'),
                      validator: Validators.required,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('profil-nom'),
                      controller: _nom,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Nom'),
                      validator: Validators.required,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('profil-telephone'),
                      controller: _telephone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        hintText: '+221 …',
                      ),
                    ),
                    const SizedBox(height: 20),
                    SubmitButton(
                      key: const Key('profil-enregistrer'),
                      label: 'Enregistrer',
                      loading: _loading,
                      onPressed: _enregistrer,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.valeur);

  final String label;
  final Widget valeur;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Couleurs.ardoise500),
          ),
          const SizedBox(height: 2),
          valeur,
        ],
      ),
    );
  }
}
