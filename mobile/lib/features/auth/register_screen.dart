import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import 'auth_provider.dart';
import 'user.dart';
import 'validators.dart';

/// Écran d'inscription (RF-01) : nom, prénom, email, téléphone, mot de passe.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  UserRole _role = UserRole.producteur;
  bool _loading = false;
  String? _error;

  /// Erreurs de validation renvoyées par l'API, affichées sous chaque champ.
  Map<String, String> _serverErrors = const {};

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _serverErrors = const {};
      _error = null;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().register(
        RegisterData(
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          email: _emailController.text.trim(),
          telephone: _telephoneController.text.replaceAll(
            RegExp(r'[\s.-]'),
            '',
          ),
          password: _passwordController.text,
          role: _role,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _serverErrors = e.fieldErrors;
        _error = e.fieldErrors.isEmpty ? e.message : null;
      });
      _formKey.currentState!.validate();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Combine la validation locale et l'erreur éventuelle renvoyée par l'API.
  FormFieldValidator<String> _validate(
    String field,
    FormFieldValidator<String> local,
  ) =>
      (value) => local(value) ?? _serverErrors[field];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      key: const Key('register-prenom'),
                      controller: _prenomController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Prénom'),
                      validator: _validate('prenom', Validators.required),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('register-nom'),
                      controller: _nomController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Nom'),
                      validator: _validate('nom', Validators.required),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('register-email'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: _validate('email', Validators.email),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('register-telephone'),
                      controller: _telephoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        hintText: '77 123 45 67',
                      ),
                      validator: _validate('telephone', Validators.telephone),
                    ),
                    const SizedBox(height: 16),
                    Text('Je suis', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    SegmentedButton<UserRole>(
                      segments: [
                        for (final role in UserRole.values)
                          ButtonSegment(value: role, label: Text(role.label)),
                      ],
                      selected: {_role},
                      onSelectionChanged: (selection) =>
                          setState(() => _role = selection.first),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('register-password'),
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Mot de passe',
                        helperText: 'Au moins 8 caractères',
                      ),
                      validator: _validate('password', Validators.password),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('register-confirm'),
                      controller: _confirmController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Confirmer le mot de passe',
                      ),
                      validator: (value) => value == _passwordController.text
                          ? null
                          : 'Les mots de passe ne correspondent pas',
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('register-submit'),
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('S\'inscrire'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
