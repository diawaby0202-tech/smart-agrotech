import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config.dart';
import 'core/notification_service.dart';
import 'core/services.dart';
import 'core/token_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final services = AppServices.create(
    storage: SecureTokenStorage(),
    useMock: AppConfig.useMock,
    notifier: kIsWeb ? NoopNotifier() : LocalNotifier(),
  );
  services.auth.restoreSession();

  runApp(SmartAgroTechApp(services: services));
}
