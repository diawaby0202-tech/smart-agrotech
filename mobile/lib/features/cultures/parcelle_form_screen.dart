import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/format.dart';
import '../../core/widgets.dart';
import '../auth/validators.dart';
import 'parcelle.dart';
import 'parcelle_repository.dart';

/// Ajout ou modification d'une parcelle (RF-06, RF-07). Renvoie `true` si la
/// liste doit être rechargée.
class ParcelleFormScreen extends StatefulWidget {
  const ParcelleFormScreen({super.key, this.parcelle});

  final Parcelle? parcelle;

  @override
  State<ParcelleFormScreen> createState() => _ParcelleFormScreenState();
}

class _ParcelleFormScreenState extends State<ParcelleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nom = TextEditingController(text: widget.parcelle?.nom);
  late final _culture = TextEditingController(text: widget.parcelle?.culture);
  late final _superficie = TextEditingController(
    text: widget.parcelle == null
        ? ''
        : formatNombre(widget.parcelle!.superficie),
  );
  late final _localisation = TextEditingController(
    text: widget.parcelle?.localisation,
  );
  late final _notes = TextEditingController(text: widget.parcelle?.notes);
  late DateTime? _dateSemis = widget.parcelle?.dateSemis;
  late DateTime? _dateRecolte = widget.parcelle?.dateRecoltePrevue;
  late StatutParcelle _statut =
      widget.parcelle?.statut ?? StatutParcelle.preparation;

  bool _loading = false;
  String? _error;
  Map<String, String> _serverErrors = const {};

  bool get _isEdit => widget.parcelle != null;

  @override
  void dispose() {
    _nom.dispose();
    _culture.dispose();
    _superficie.dispose();
    _localisation.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _validerSuperficie(String? value) {
    final missing = Validators.required(value);
    if (missing != null) return missing;
    final nombre = double.tryParse(value!.trim().replaceAll(',', '.'));
    if (nombre == null || nombre <= 0) return 'Nombre positif attendu';
    return _serverErrors['superficie'];
  }

  Future<void> _submit() async {
    setState(() {
      _serverErrors = const {};
      _error = null;
    });
    if (!_formKey.currentState!.validate()) return;

    final parcelle = Parcelle(
      id: widget.parcelle?.id,
      nom: _nom.text.trim(),
      culture: _culture.text.trim(),
      superficie: double.parse(_superficie.text.trim().replaceAll(',', '.')),
      localisation: _localisation.text.trim(),
      dateSemis: _dateSemis,
      dateRecoltePrevue: _dateRecolte,
      statut: _statut,
      notes: _notes.text.trim(),
    );

    setState(() => _loading = true);
    final repository = context.read<ParcelleRepository>();
    try {
      await (_isEdit
          ? repository.update(parcelle)
          : repository.create(parcelle));
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
      titre: 'Supprimer la parcelle ?',
      message: 'La parcelle « ${widget.parcelle!.nom} » sera supprimée.',
    );
    if (!ok || !mounted) return;
    try {
      await context.read<ParcelleRepository>().delete(widget.parcelle!.id!);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showMessage(context, messageErreur(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier la parcelle' : 'Nouvelle parcelle'),
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
              key: const Key('parcelle-nom'),
              controller: _nom,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nom de la parcelle',
              ),
              validator: (v) => Validators.required(v) ?? _serverErrors['nom'],
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('parcelle-culture'),
              controller: _culture,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Culture',
                hintText: 'Arachide, mil, riz, tomate…',
              ),
              validator: (v) =>
                  Validators.required(v) ?? _serverErrors['culture'],
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('parcelle-superficie'),
              controller: _superficie,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Superficie',
                suffixText: 'ha',
              ),
              validator: _validerSuperficie,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _localisation,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Localisation (ville ou zone)',
                helperText: 'Sert aux alertes météo de cette parcelle',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<StatutParcelle>(
              initialValue: _statut,
              decoration: const InputDecoration(labelText: 'Étape'),
              items: [
                for (final statut in StatutParcelle.values)
                  DropdownMenuItem(value: statut, child: Text(statut.label)),
              ],
              onChanged: (value) => setState(() => _statut = value!),
            ),
            const SizedBox(height: 16),
            DateField(
              label: 'Date de semis',
              value: _dateSemis,
              onChanged: (date) => setState(() => _dateSemis = date),
            ),
            const SizedBox(height: 16),
            DateField(
              label: 'Date de récolte prévue',
              value: _dateRecolte,
              onChanged: (date) => setState(() => _dateRecolte = date),
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
              key: const Key('parcelle-submit'),
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
