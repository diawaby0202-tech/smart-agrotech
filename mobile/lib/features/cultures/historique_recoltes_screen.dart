import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/design.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../auth/validators.dart';
import 'parcelle.dart';
import 'parcelle_repository.dart';
import 'recolte.dart';

class HistoriqueRecoltesScreen extends StatefulWidget {
  const HistoriqueRecoltesScreen({super.key, required this.parcelle});

  final Parcelle parcelle;

  @override
  State<HistoriqueRecoltesScreen> createState() =>
      _HistoriqueRecoltesScreenState();
}

class _HistoriqueRecoltesScreenState extends State<HistoriqueRecoltesScreen> {
  final _listKey = GlobalKey<AsyncViewState<List<Recolte>>>();

  Future<List<Recolte>> _load() => context
      .read<ParcelleRepository>()
      .recoltes(widget.parcelle.id!);

  Future<void> _ajouter() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RecolteFormScreen(parcelle: widget.parcelle),
      ),
    );
    if (changed == true) _listKey.currentState?.reload();
  }

  Future<void> _supprimer(Recolte recolte) async {
    final ok = await confirmer(
      context,
      titre: 'Supprimer cette récolte ?',
      message:
          '${formatNombre(recolte.quantite)} ${recolte.unite.label} '
          'du ${formatDate(recolte.date)}',
    );
    if (!ok || !mounted) return;
    try {
      await context.read<ParcelleRepository>().deleteRecolte(recolte.id!);
      _listKey.currentState?.reload();
    } catch (e) {
      if (mounted) showMessage(context, messageErreur(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rendements — ${widget.parcelle.nom}')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('recolte-ajouter'),
        onPressed: _ajouter,
        icon: const Icon(Icons.add),
        label: const Text('Enregistrer une récolte'),
      ),
      body: AsyncView<List<Recolte>>(
        key: _listKey,
        load: _load,
        builder: (context, recoltes) {
          final totaux = <UniteRecolte, double>{};
          for (final recolte in recoltes) {
            totaux.update(
              recolte.unite,
              (total) => total + recolte.quantite,
              ifAbsent: () => recolte.quantite,
            );
          }
          final kilogrammes =
              (totaux[UniteRecolte.kg] ?? 0) +
              (totaux[UniteRecolte.tonne] ?? 0) * 1000;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Encadre(
                icone: Icons.agriculture_outlined,
                texte:
                    'Consignez les quantités récoltées pour suivre le '
                              'rendement de ${widget.parcelle.nom}.',
                fond: Couleurs.vert50,
                couleur: Couleurs.vert700,
              ),
              if (totaux.isNotEmpty) ...[
                const SizedBox(height: 16),
                if (kilogrammes > 0 && widget.parcelle.superficie > 0)
                  Text(
                    'Rendement cumulé : '
                    '${formatNombre(kilogrammes / widget.parcelle.superficie)} '
                    'kg/ha',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Couleurs.vert700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (kilogrammes > 0 && widget.parcelle.superficie > 0)
                  const SizedBox(height: 8),
                Text(
                  'Quantités enregistrées',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final total in totaux.entries)
                      Chip(
                        label: Text(
                          '${formatNombre(total.value)} ${total.key.label}',
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              if (recoltes.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'Aucune récolte enregistrée pour cette parcelle.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final recolte in recoltes)
                Card(
                  key: Key('recolte-${recolte.id}'),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Couleurs.vert100,
                      foregroundColor: Couleurs.vert700,
                      child: Icon(Icons.grass),
                    ),
                    title: Text(
                      '${formatNombre(recolte.quantite)} '
                      '${recolte.unite.label}',
                    ),
                    subtitle: Text(
                      [
                        formatDateLongue(recolte.date),
                        if (recolte.notes.isNotEmpty) recolte.notes,
                      ].join('\n'),
                    ),
                    isThreeLine: recolte.notes.isNotEmpty,
                    trailing: IconButton(
                      tooltip: 'Supprimer',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _supprimer(recolte),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class RecolteFormScreen extends StatefulWidget {
  const RecolteFormScreen({super.key, required this.parcelle});

  final Parcelle parcelle;

  @override
  State<RecolteFormScreen> createState() => _RecolteFormScreenState();
}

class _RecolteFormScreenState extends State<RecolteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantite = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _date = DateTime.now();
  UniteRecolte _unite = UniteRecolte.kg;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _quantite.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _validerQuantite(String? value) {
    final missing = Validators.required(value);
    if (missing != null) return missing;
    final quantite = double.tryParse(value!.trim().replaceAll(',', '.'));
    if (quantite == null || quantite <= 0) {
      return 'Saisissez une quantité supérieure à zéro.';
    }
    return null;
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    final parcelleId = widget.parcelle.id;
    final date = _date;
    if (parcelleId == null || date == null) {
      setState(() => _error = 'La parcelle et la date sont obligatoires.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<ParcelleRepository>().createRecolte(
        Recolte(
          parcelleId: parcelleId,
          date: date,
          quantite: double.parse(
            _quantite.text.trim().replaceAll(',', '.'),
          ),
          unite: _unite,
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
      appBar: AppBar(title: const Text('Enregistrer une récolte')),
      body: Form(
        key: _formKey,
        child: FormBody(
          children: [
            Encadre(
              icone: Icons.agriculture_outlined,
              texte: '${widget.parcelle.nom} · ${widget.parcelle.culture}',
              fond: Couleurs.vert50,
              couleur: Couleurs.vert700,
            ),
            const SizedBox(height: 16),
            DateField(
              label: 'Date de récolte',
              value: _date,
              errorText: _date == null ? 'Champ obligatoire' : null,
              onChanged: (date) => setState(() => _date = date),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('recolte-quantite'),
              controller: _quantite,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Quantité récoltée'),
              validator: _validerQuantite,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<UniteRecolte>(
              initialValue: _unite,
              decoration: const InputDecoration(labelText: 'Unité'),
              items: [
                for (final unite in UniteRecolte.values)
                  DropdownMenuItem(
                    value: unite,
                    child: Text(unite.label),
                  ),
              ],
              onChanged: (unite) {
                if (unite != null) setState(() => _unite = unite);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('recolte-notes'),
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
              key: const Key('recolte-submit'),
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
