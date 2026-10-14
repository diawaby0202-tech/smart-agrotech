import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/config.dart';
import 'auth_provider.dart';
import 'mock_auth_repository.dart';
import 'validators.dart';
import '../../core/design.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// Écran de connexion (RF-02). La redirection vers l'accueil est faite par le
/// routeur dès que [AuthProvider] passe à l'état connecté.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().login(
        _emailController.text,
        _passwordController.text,
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Ouvre l'inscription. Au retour, si un compte vient d'être créé, son
  /// email est pré-rempli et un message de confirmation s'affiche.
  Future<void> _openRegister() async {
    final email = await context.push<String>('/inscription');
    if (email == null || !mounted) return;
    setState(() {
      _emailController.text = email;
      _passwordController.clear();
      _error = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Compte créé. Connectez-vous pour continuer.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Couleurs.vert50,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const EnteteMarque(),
                  const SizedBox(height: 24),
                  CarteFormulaire(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: LogoMarque()),
                          const SizedBox(height: 16),
                          Text(
                            'Connexion',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Accédez à votre espace Smart AgroTech.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Couleurs.ardoise500,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_error != null) ...[
                            Encadre(
                              icone: '⚠️',
                              texte: _error!,
                              fond: Couleurs.dangerClair,
                              couleur: Couleurs.danger,
                            ),
                            const SizedBox(height: 16),
                          ],
                          TextFormField(
                            key: const Key('login-email'),
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'Adresse e-mail',
                              hintText: 'exemple@domaine.sn',
                            ),
                            validator: Validators.email,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: const Key('login-password'),
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              hintText: 'Votre mot de passe',
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Afficher'
                                    : 'Masquer',
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            validator: Validators.required,
                          ),
                          const SizedBox(height: 24),
                          SubmitButton(
                            key: const Key('login-submit'),
                            label: 'Se connecter',
                            loading: _loading,
                            onPressed: _submit,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text('Pas encore de compte ?'),
                              TextButton(
                                key: const Key('login-inscription'),
                                onPressed: _loading ? null : _openRegister,
                                child: const Text('Créer un compte'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (AppConfig.useMock) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Mode démo (données fictives)\n'
                      '${MockAuthRepository.demoEmail} / '
                      '${MockAuthRepository.demoPassword}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
