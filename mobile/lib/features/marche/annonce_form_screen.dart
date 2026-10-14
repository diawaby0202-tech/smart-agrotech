import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/widgets.dart';
import '../auth/validators.dart';
import 'annonce.dart';
import 'annonce_repository.dart';

/// Publication ou modification d'une annonce (RF-16, RF-19). Renvoie `true`
/// si les listes doivent être rechargées.
class AnnonceFormScreen extends StatefulWidget {
  const AnnonceFormScreen({super.key, this.annonce});

  final Annonce? annonce;

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

  /// Photo choisie dans la galerie, pas encore envoyée.
  XFile? _photo;

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

  Future<void> _choisirPhoto() async {
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (photo != null && mounted) setState(() => _photo = photo);
    } catch (_) {
      if (mounted) showMessage(context, 'Impossible d\'ouvrir la galerie.');
    }
  }

  Future<void> _submit() async {
    setState(() {
      _serverErrors = const {};
      _error = null;
    });
    if (!_formKey.currentState!.validate()) return;

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
    final aUnePhoto =
        _photo != null || (widget.annonce?.photoUrl.isNotEmpty ?? false);

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
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _choisirPhoto,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(
                _photo != null
                    ? 'Photo choisie : ${_photo!.name}'
                    : aUnePhoto
                    ? 'Remplacer la photo'
                    : 'Ajouter une photo',
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
