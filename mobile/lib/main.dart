import 'package:flutter/material.dart';

import 'app.dart';
import 'core/api_client.dart';
import 'core/config.dart';
import 'core/token_storage.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/mock_auth_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = SecureTokenStorage();
  final apiClient = ApiClient(storage: storage);
  final AuthRepository repository = AppConfig.useMock
      ? MockAuthRepository(storage)
      : ApiAuthRepository(apiClient, storage);

  final auth = AuthProvider(repository);
  apiClient.onSessionExpired = auth.onSessionExpired;
  auth.restoreSession();

  runApp(SmartAgroTechApp(auth: auth));
}
