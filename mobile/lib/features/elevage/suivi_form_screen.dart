import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/widgets.dart';
import 'elevage_models.dart';
import 'elevage_repository.dart';

/// Enregistrement d'une intervention sanitaire (RF-11). Renvoie `true` si un
/// suivi a été créé.
class SuiviFormScreen extends StatefulWidget {
  const SuiviFormScreen({super.key, required this.animal});

  final Animal animal;

  @override
  State<SuiviFormScreen> createState() => _SuiviFormScreenState();
}

class _SuiviFormScreenState extends State<SuiviFormScreen> {
  final _description = TextEditingController();
  TypeSuivi _type = TypeSuivi.vaccination;
  DateTime? _date = DateTime.now();
  DateTime? _echeance;

  bool _loading = false;
  String? _error;
  String? _dateError;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final date = _date;
    setState(() {
      _error = null;
      _dateError = date == null ? 'Champ obligatoire' : null;
    });
    if (date == null) return;

    setState(() => _loading = true);
    try {
      await context.read<ElevageRepository>().createSuivi(
        SuiviSanitaire(
          animalId: widget.animal.id!,
          type: _type,
          date: date,
          description: _description.text.trim(),
          prochaineEcheance: _echeance,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Suivi — ${widget.animal.titre}')),
      body: FormBody(
        children: [
          SegmentedButton<TypeSuivi>(
            segments: [
              for (final type in TypeSuivi.values)
                ButtonSegment(
                  value: type,
                  label: Text(type == TypeSuivi.visite ? 'Visite' : type.label),
                ),
            ],
            selected: {_type},
            onSelectionChanged: (selection) =>
                setState(() => _type = selection.first),
          ),
          const SizedBox(height: 16),
          DateField(
            label: 'Date de l\'intervention',
            value: _date,
            errorText: _dateError,
            onChanged: (date) => setState(() => _date = date),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('suivi-description'),
            controller: _description,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Vaccin, médicament, observations…',
            ),
          ),
          const SizedBox(height: 16),
          DateField(
            label: 'Prochaine échéance (rappel)',
            value: _echeance,
            onChanged: (date) => setState(() => _echeance = date),
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
            key: const Key('suivi-submit'),
            label: 'Enregistrer',
            loading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
