import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/notification_service.dart';
import 'core/router.dart';
import 'core/services.dart';
import 'features/alertes/alertes_repository.dart';
import 'features/auth/auth_provider.dart';
import 'features/cultures/parcelle_repository.dart';
import 'features/elevage/elevage_repository.dart';
import 'features/marche/annonce_repository.dart';

class SmartAgroTechApp extends StatefulWidget {
  const SmartAgroTechApp({super.key, required this.services});

  final AppServices services;

  @override
  State<SmartAgroTechApp> createState() => _SmartAgroTechAppState();
}

class _SmartAgroTechAppState extends State<SmartAgroTechApp> {
  late final GoRouter _router = createRouter(widget.services.auth);
  AuthStatus? _lastStatus;

  @override
  void initState() {
    super.initState();
    widget.services.auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  /// À la connexion : récupère les rappels et alertes et notifie les
  /// nouveaux. À la déconnexion : oublie ceux de l'utilisateur précédent.
  void _onAuthChanged() {
    final status = widget.services.auth.status;
    if (status == _lastStatus) return;
    final wasAuthenticated = _lastStatus == AuthStatus.authenticated;
    _lastStatus = status;
    if (status == AuthStatus.authenticated) {
      widget.services.rappels.synchroniser();
    } else if (wasAuthenticated) {
      widget.services.rappels.reinitialiser();
    }
  }

  @override
  void dispose() {
    widget.services.auth.removeListener(_onAuthChanged);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = widget.services;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: services.auth),
        Provider<ParcelleRepository>.value(value: services.parcelles),
        Provider<ElevageRepository>.value(value: services.elevage),
        Provider<AlertesRepository>.value(value: services.alertes),
        Provider<AnnonceRepository>.value(value: services.annonces),
        Provider<RappelService>.value(value: services.rappels),
      ],
      child: MaterialApp.router(
        title: 'Smart AgroTech',
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ),
    );
  }
}
