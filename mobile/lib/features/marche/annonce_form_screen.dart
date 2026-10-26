import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:flutter/foundation.dart';

import '../../core/api_exception.dart';
import '../../core/design.dart' as design;
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../core/format.dart';
import '../auth/auth_provider.dart';
import '../auth/profil_screen.dart';
import '../auth/validators.dart';
import 'annonce.dart';
import 'annonce_repository.dart';

/// Publication ou modification d'une annonce (RF-16, RF-19). Renvoie `true`
/// si les listes doivent être rechargées.
class AnnonceFormScreen extends StatefulWidget {
  const AnnonceFormScreen({super.key, this.annonce});

  final Annonce? annonce;

  /// Ouvre la galerie ou l'appareil photo. Remplaçable dans les tests.
  static Future<XFile?> Function(ImageSource source) choisirImage = (source) =>
      ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 80);

  @override
  State<AnnonceFormScreen> createState() => _AnnonceFormScreenState();
}

class _AnnonceFormScreenState extends State<AnnonceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _titre = TextEditingController(text: widget.annonce?.titre);
  late final _description = TextEditingController(
    text: widget.annonce?.description,
  );
  late final _prix = TextEditingController(
    text: widget.annonce?.prix.toString(),
  );
  late final _quantite = TextEditingController(text: widget.annonce?.quantite);
  late final _zone = TextEditingController(text: widget.annonce?.zone);
  late CategorieAnnonce? _categorie = widget.annonce?.categorie;
  late StatutAnnonce _statut =
      widget.annonce?.statut ?? StatutAnnonce.disponible;

  /// Photo choisie sur le téléphone, pas encore envoyée.
  XFile? _photo;
  Uint8List? _apercu;
  String? _erreurPhoto;

  bool _loading = false;
  String? _error;
  Map<String, String> _serverErrors = const {};

  bool get _isEdit => widget.annonce != null;

  @override
  void dispose() {
    _titre.dispose();
    _description.dispose();
    _prix.dispose();
    _quantite.dispose();
    _zone.dispose();
    super.dispose();
  }

  String? _validerPrix(String? value) {
    final prix = int.tryParse(value?.trim() ?? '');
    if (prix == null || prix < 0) return 'Prix en FCFA, sans virgule';
    return _serverErrors['prix'];
  }

  Future<void> _choisirPhoto(ImageSource source) async {
    try {
      final photo = await AnnonceFormScreen.choisirImage(source);
      if (photo == null) return;
      final apercu = await photo.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photo = photo;
        _apercu = apercu;
        _erreurPhoto = null;
      });
    } catch (_) {
      if (mounted) {
        showMessage(
          context,
          source == ImageSource.camera
              ? 'Impossible d\'ouvrir l\'appareil photo.'
              : 'Impossible d\'ouvrir la galerie.',
        );
      }
    }
  }

  /// Le numéro affiché sur l'annonce est celui du profil du vendeur.
  bool get _aUnTelephone =>
      context.read<AuthProvider>().user?.telephone.isNotEmpty ?? false;

  /// Une annonce doit toujours avoir une photo du produit.
  bool get _aUnePhoto =>
      _photo != null || (widget.annonce?.photoUrl.isNotEmpty ?? false);

  Future<void> _submit() async {
    setState(() {
      _serverErrors = const {};
      _error = null;
      _erreurPhoto = _aUnePhoto ? null : 'Ajoutez une photo de votre produit.';
    });
    final formulaireValide = _formKey.currentState!.validate();
    if (!formulaireValide || !_aUnePhoto) return;
    if (!_aUnTelephone) {
      setState(
        () => _error =
            'Ajoutez votre numéro de téléphone dans « Mon profil » : les '
            'acheteurs en ont besoin pour vous contacter.',
      );
      return;
    }

    final annonce = Annonce(
      id: widget.annonce?.id,
      titre: _titre.text.trim(),
      description: _description.text.trim(),
      categorie: _categorie!,
      prix: int.parse(_prix.text.trim()),
      quantite: _quantite.text.trim(),
      zone: _zone.text.trim(),
      statut: _statut,
      photoUrl: widget.annonce?.photoUrl ?? '',
      vendeurNom: widget.annonce?.vendeurNom ?? '',
      vendeurTelephone: widget.annonce?.vendeurTelephone ?? '',
      estProprietaire: true,
      dateCreation: widget.annonce?.dateCreation,
    );

    setState(() => _loading = true);
    final repository = context.read<AnnonceRepository>();
    try {
      await (_isEdit
          ? repository.update(annonce, imagePath: _photo?.path)
          : repository.create(annonce, imagePath: _photo?.path));
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _serverErrors = e.fieldErrors;
        _error = e.message;
      });
      _formKey.currentState!.validate();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final ok = await confirmer(
      context,
      titre: 'Supprimer l\'annonce ?',
      message:
          '« ${widget.annonce!.titre} » ne sera plus visible sur le marché.',
    );
    if (!ok || !mounted) return;
    try {
      await context.read<AnnonceRepository>().delete(widget.annonce!.id!);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showMessage(context, messageErreur(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier l\'annonce' : 'Publier une annonce'),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: 'Supprimer',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: FormBody(
          children: [
            TextFormField(
              key: const Key('annonce-titre'),
              controller: _titre,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Titre'),
              validator: (v) =>
                  Validators.required(v) ?? _serverErrors['titre'],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CategorieAnnonce>(
              key: const Key('annonce-categorie'),
              initialValue: _categorie,
              decoration: const InputDecoration(labelText: 'Catégorie'),
              items: [
                for (final categorie in CategorieAnnonce.values)
                  DropdownMenuItem(
                    value: categorie,
                    child: Text(categorie.label),
                  ),
              ],
              onChanged: (value) => setState(() => _categorie = value),
              validator: (value) => value == null ? 'Champ obligatoire' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('annonce-prix'),
              controller: _prix,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Prix',
                suffixText: 'FCFA',
              ),
              validator: _validerPrix,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantite,
              decoration: const InputDecoration(
                labelText: 'Quantité',
                hintText: '50 kg, 3 têtes…',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _zone,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Zone',
                hintText: 'Ville ou région',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            if (_isEdit) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<StatutAnnonce>(
                initialValue: _statut,
                decoration: const InputDecoration(labelText: 'Statut'),
                items: [
                  for (final statut in StatutAnnonce.values)
                    DropdownMenuItem(value: statut, child: Text(statut.label)),
                ],
                onChanged: (value) => setState(() => _statut = value!),
              ),
            ],
            const SizedBox(height: 16),
            _ZonePhoto(
              apercu: _apercu,
              photoExistante: widget.annonce?.photoUrl ?? '',
              erreur: _erreurPhoto,
              onGalerie: () => _choisirPhoto(ImageSource.gallery),
              onCamera: () => _choisirPhoto(ImageSource.camera),
            ),
            const SizedBox(height: 16),
            const _CoordonneesVendeur(),
            if (_serverErrors['image'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _serverErrors['image']!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            SubmitButton(
              key: const Key('annonce-submit'),
              label: _isEdit ? 'Enregistrer' : 'Publier',
              loading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

/// Photo de l'annonce : aperçu, puis choix dans la galerie ou prise de vue.
class _ZonePhoto extends StatelessWidget {
  const _ZonePhoto({
    required this.apercu,
    required this.photoExistante,
    required this.erreur,
    required this.onGalerie,
    required this.onCamera,
  });

  final Uint8List? apercu;
  final String photoExistante;
  final String? erreur;
  final VoidCallback onGalerie;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final image = apercu != null
        ? Image.memory(apercu!, fit: BoxFit.cover)
        : photoExistante.isNotEmpty
        ? design.ImageSource(photoExistante)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Photo du produit *', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: Couleurs.ardoise100,
              border: Border.all(
                color: erreur != null ? Couleurs.danger : Couleurs.ardoise200,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child:
                image ??
                const Center(
                  child: Text(
                    '📷  Aucune photo',
                    style: TextStyle(color: Couleurs.ardoise500),
                  ),
                ),
          ),
        ),
        if (erreur != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              erreur!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('annonce-galerie'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: onGalerie,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galerie'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('annonce-camera'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: onCamera,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Appareil photo'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Coordonnées que les acheteurs verront sur l'annonce (nom et téléphone du
/// profil), avec un accès direct au profil pour les compléter.
class _CoordonneesVendeur extends StatelessWidget {
  const _CoordonneesVendeur();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().user;
    final telephone = user?.telephone ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: telephone.isEmpty ? Couleurs.dangerClair : Couleurs.vert50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: telephone.isEmpty ? Couleurs.danger : Couleurs.vert100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vos coordonnées sur l\'annonce',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text('👤  ${user?.nomComplet ?? ''}'),
          const SizedBox(height: 2),
          Text(
            telephone.isEmpty
                ? '📞  Aucun numéro dans votre profil'
                : '📞  ${formatTelephone(telephone)}',
            style: TextStyle(
              color: telephone.isEmpty ? Couleurs.danger : null,
              fontWeight: telephone.isEmpty ? FontWeight.w700 : null,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            key: const Key('annonce-modifier-profil'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProfilScreen()),
            ),
            child: Text(
              telephone.isEmpty
                  ? 'Ajouter mon numéro dans « Mon profil »'
                  : 'Modifier dans « Mon profil »',
            ),
          ),
        ],
      ),
    );
  }
}
