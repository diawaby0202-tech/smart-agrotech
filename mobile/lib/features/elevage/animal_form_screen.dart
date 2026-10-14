import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/widgets.dart';
import '../auth/validators.dart';
import 'elevage_models.dart';
import 'elevage_repository.dart';

/// Ajout ou modification d'un animal / lot (RF-10).
///
/// Renvoie l'[Animal] enregistré, ou `true` s'il a été supprimé.
class AnimalFormScreen extends StatefulWidget {
  const AnimalFormScreen({super.key, this.animal});

  final Animal? animal;

  @override
  State<AnimalFormScreen> createState() => _AnimalFormScreenState();
}

class _AnimalFormScreenState extends State<AnimalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _espece = TextEditingController(text: widget.animal?.espece);
  late final _race = TextEditingController(text: widget.animal?.race);
  late final _identifiant = TextEditingController(
    text: widget.animal?.identifiant,
  );
  late final _effectif = TextEditingController(
    text: '${widget.animal?.effectif ?? 1}',
  );
  late final _notes = TextEditingController(text: widget.animal?.notes);
  late DateTime? _dateNaissance = widget.animal?.dateNaissance;

  bool _loading = false;
  String? _error;
  Map<String, String> _serverErrors = const {};

  bool get _isEdit => widget.animal != null;

  @override
  void dispose() {
    _espece.dispose();
    _race.dispose();
    _identifiant.dispose();
    _effectif.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _validerEffectif(String? value) {
    final nombre = int.tryParse(value?.trim() ?? '');
    if (nombre == null || nombre < 1) return 'Nombre entier d\'au moins 1';
    return _serverErrors['effectif'];
  }

  Future<void> _submit() async {
    setState(() {
      _serverErrors = const {};
      _error = null;
    });
    if (!_formKey.currentState!.validate()) return;

    final animal = Animal(
      id: widget.animal?.id,
      espece: _espece.text.trim(),
      race: _race.text.trim(),
      identifiant: _identifiant.text.trim(),
      effectif: int.parse(_effectif.text.trim()),
      dateNaissance: _dateNaissance,
      notes: _notes.text.trim(),
    );

    setState(() => _loading = true);
    final repository = context.read<ElevageRepository>();
    try {
      final saved = await (_isEdit
          ? repository.updateAnimal(animal)
          : repository.createAnimal(animal));
      if (!mounted) return;
      Navigator.of(context).pop<Object>(_isEdit ? saved : true);
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
      titre: 'Supprimer cet animal ?',
      message:
          '« ${widget.animal!.titre} » et son suivi sanitaire seront supprimés.',
    );
    if (!ok || !mounted) return;
    try {
      await context.read<ElevageRepository>().deleteAnimal(widget.animal!.id!);
      if (mounted) Navigator.of(context).pop<Object>(true);
    } catch (e) {
      if (mounted) showMessage(context, messageErreur(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier l\'animal' : 'Nouvel animal ou lot'),
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
              key: const Key('animal-espece'),
              controller: _espece,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Espèce',
                hintText: 'Vache, mouton, chèvre, poulet…',
              ),
              validator: (v) =>
                  Validators.required(v) ?? _serverErrors['espece'],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _race,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Race'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('animal-identifiant'),
              controller: _identifiant,
              decoration: const InputDecoration(
                labelText: 'Identifiant',
                hintText: 'Numéro de boucle ou nom du lot',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('animal-effectif'),
              controller: _effectif,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Effectif',
                helperText: '1 = animal seul, plus de 1 = lot',
              ),
              validator: _validerEffectif,
            ),
            const SizedBox(height: 16),
            DateField(
              label: 'Date de naissance',
              value: _dateNaissance,
              onChanged: (date) => setState(() => _dateNaissance = date),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes'),
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
              key: const Key('animal-submit'),
              label: 'Enregistrer',
              loading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
