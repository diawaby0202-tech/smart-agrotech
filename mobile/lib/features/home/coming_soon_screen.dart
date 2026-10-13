import 'package:flutter/material.dart';

/// Écran provisoire d'un module pas encore développé.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.titre, required this.icon});

  final String titre;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(titre)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('Bientôt disponible', style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
