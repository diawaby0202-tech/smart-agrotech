import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/design.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'elevage_models.dart';
import 'elevage_repository.dart';

class SuiviReproductionScreen extends StatefulWidget {
  const SuiviReproductionScreen({super.key, required this.animal});

  final Animal animal;

  @override
  State<SuiviReproductionScreen> createState() =>
      _SuiviReproductionScreenState();
}

class _SuiviReproductionScreenState extends State<SuiviReproductionScreen> {
  final _listKey = GlobalKey<AsyncViewState<List<SuiviReproduction>>>();

  Future<List<SuiviReproduction>> _load() => context
      .read<ElevageRepository>()
      .reproductions(widget.animal.id!);

  Future<void> _ajouter() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SuiviReproductionFormScreen(animal: widget.animal),
      ),
    );
    if (changed == true) _listKey.currentState?.reload();
  }

  Future<void> _supprimer(SuiviReproduction suivi) async {
    final ok = await confirmer(
      context,
      titre: 'Supprimer ce suivi ?',
      message: 'Cette entrée de reproduction sera supprimée.',
    );
    if (!ok || !mounted) return;
    try {
      await context.read<ElevageRepository>().deleteReproduction(suivi.id!);
      _listKey.currentState?.reload();
    } catch (e) {
      if (mounted) showMessage(context, messageErreur(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reproduction — ${widget.animal.titre}')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('reproduction-ajouter'),
        onPressed: _ajouter,
        icon: const Icon(Icons.add),
        label: const Text('Nouvel événement'),
      ),
      body: AsyncView<List<SuiviReproduction>>(
        key: _listKey,
        load: _load,
        builder: (context, suivis) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Encadre(
              icone: Icons.pets_outlined,
              texte: 'Historique de reproduction de ${widget.animal.titre}.',
              fond: Couleurs.vert50,
              couleur: Couleurs.vert700,
            ),
            const SizedBox(height: 16),
            if (suivis.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'Aucun événement de reproduction enregistré.',
                  textAlign: TextAlign.center,
                ),
              ),
            for (final suivi in suivis)
              Card(
                key: Key('reproduction-${suivi.id}'),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: suivi.miseBasReelle == null
                        ? Couleurs.or100
                        : Couleurs.vert100,
                    foregroundColor: Couleurs.vert700,
                    child: Icon(
                      suivi.miseBasReelle == null
                          ? Icons.pregnant_woman
                          : Icons.child_care,
                    ),
                  ),
                  title: Text(
                    suivi.miseBasReelle == null
                        ? 'Gestation / suivi en cours'
                        : 'Mise bas enregistrée',
                  ),
                  subtitle: Text(
                    [
                      if (suivi.dateSaillie != null)
                        'Saillie : ${formatDateLongue(suivi.dateSaillie)}',
                      if (suivi.miseBasPrevue != null)
                        'Mise bas prévue : '
                            '${formatDateLongue(suivi.miseBasPrevue)}',
                      if (suivi.miseBasReelle != null)
                        'Mise bas réelle : '
                            '${formatDateLongue(suivi.miseBasReelle)}',
                      if (suivi.nombrePetits != null)
                        'Nombre de petits : ${suivi.nombrePetits}',
                      if (suivi.notes.isNotEmpty) suivi.notes,
                    ].join('\n'),
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    tooltip: 'Supprimer',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _supprimer(suivi),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SuiviReproductionFormScreen extends StatefulWidget {
  const SuiviReproductionFormScreen({super.key, required this.animal});

  final Animal animal;

  @override
  State<SuiviReproductionFormScreen> createState() =>
      _SuiviReproductionFormScreenState();
}

class _SuiviReproductionFormScreenState
    extends State<SuiviReproductionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombrePetits = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _dateSaillie = DateTime.now();
  DateTime? _miseBasPrevue;
  DateTime? _miseBasReelle;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nombrePetits.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _validerNombre(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final nombre = int.tryParse(value.trim());
    if (nombre == null || nombre < 0) {
      return 'Saisissez un nombre entier positif ou nul.';
    }
    return null;
  }

  Future<void> _enregistrer() async {
    final formValide = _formKey.currentState!.validate();
    final animalId = widget.animal.id;
    if (animalId == null) {
      setState(() => _error = 'Enregistrez d’abord cet animal.');
      return;
    }
    if (!formValide) return;
    if (_dateSaillie == null &&
        _miseBasPrevue == null &&
        _miseBasReelle == null) {
      setState(() => _error = 'Renseignez au moins une date.');
      return;
    }
    if (_dateSaillie != null &&
        ((_miseBasPrevue != null &&
                _miseBasPrevue!.isBefore(_dateSaillie!)) ||
            (_miseBasReelle != null &&
                _miseBasReelle!.isBefore(_dateSaillie!)))) {
      setState(
        () => _error = 'Les dates de mise bas doivent suivre la saillie.',
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<ElevageRepository>().createReproduction(
        SuiviReproduction(
          animalId: animalId,
          dateSaillie: _dateSaillie,
          miseBasPrevue: _miseBasPrevue,
          miseBasReelle: _miseBasReelle,
          nombrePetits: int.tryParse(_nombrePetits.text.trim()),
          notes: _notes.text.trim(),
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
      appBar: AppBar(title: const Text('Nouvel événement de reproduction')),
      body: Form(
        key: _formKey,
        child: FormBody(
          children: [
            Encadre(
              icone: Icons.pets_outlined,
              texte: widget.animal.titre,
              fond: Couleurs.vert50,
              couleur: Couleurs.vert700,
            ),
            const SizedBox(height: 16),
            DateField(
              label: 'Date de saillie',
              value: _dateSaillie,
              onChanged: (date) => setState(() => _dateSaillie = date),
            ),
            const SizedBox(height: 16),
            DateField(
              label: 'Mise bas prévue',
              value: _miseBasPrevue,
              onChanged: (date) => setState(() => _miseBasPrevue = date),
            ),
            const SizedBox(height: 16),
            DateField(
              label: 'Mise bas réelle',
              value: _miseBasReelle,
              onChanged: (date) => setState(() => _miseBasReelle = date),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('reproduction-nombre-petits'),
              controller: _nombrePetits,
              keyboardType: TextInputType.number,
              validator: _validerNombre,
              decoration: const InputDecoration(
                labelText: 'Nombre de petits (facultatif)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('reproduction-notes'),
              controller: _notes,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes (facultatif)',
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
              key: const Key('reproduction-submit'),
              label: 'Enregistrer',
              loading: _loading,
              onPressed: _enregistrer,
            ),
          ],
        ),
      ),
    );
  }
}
