import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/alertes/meteo_screen.dart';
import '../features/auth/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/cultures/cultures_screen.dart';
import '../features/elevage/elevage_screen.dart';
import '../features/home/accueil_screen.dart';
import '../features/home/dashboard_screen.dart';
import '../features/home/home_shell.dart';
import '../features/marche/marche_screen.dart';

const _publicRoutes = {'/connexion', '/inscription'};

/// Routes de l'application. La redirection dépend de l'état de connexion :
/// un visiteur est renvoyé vers `/connexion`, un utilisateur connecté vers
/// l'accueil.
GoRouter createRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final location = state.matchedLocation;
      switch (auth.status) {
        case AuthStatus.unknown:
          return location == '/demarrage' ? null : '/demarrage';
        case AuthStatus.unauthenticated:
          return _publicRoutes.contains(location) ? null : '/connexion';
        case AuthStatus.authenticated:
          final onPublicPage =
              _publicRoutes.contains(location) || location == '/demarrage';
          return onPublicPage ? '/' : null;
      }
    },
    routes: [
      GoRoute(
        path: '/demarrage',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: '/connexion',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/inscription',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/tableau-de-bord',
        builder: (context, state) => const DashboardScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          _branch('/', const AccueilScreen()),
          _branch('/cultures', const CulturesScreen()),
          _branch('/elevage', const ElevageScreen()),
          _branch('/meteo', const MeteoScreen()),
          _branch('/marche', const MarcheScreen()),
        ],
      ),
    ],
  );
}

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (context, state) => screen)],
);
