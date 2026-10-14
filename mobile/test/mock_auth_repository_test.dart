import 'package:flutter_test/flutter_test.dart';
import 'package:smart_agrotech/core/api_exception.dart';
import 'package:smart_agrotech/core/token_storage.dart';
import 'package:smart_agrotech/features/auth/mock_auth_repository.dart';
import 'package:smart_agrotech/features/auth/user.dart';

void main() {
  late InMemoryTokenStorage storage;
  late MockAuthRepository repository;

  const nouveau = RegisterData(
    nom: 'Ndiaye',
    prenom: 'Moussa',
    email: 'moussa@example.sn',
    telephone: '781234567',
    password: 'motdepasse',
    role: UserRole.acheteur,
  );

  setUp(() {
    storage = InMemoryTokenStorage();
    repository = MockAuthRepository(storage, delay: Duration.zero);
  });

  test('connexion avec le compte de démonstration', () async {
    final user = await repository.login(
      MockAuthRepository.demoEmail,
      MockAuthRepository.demoPassword,
    );

    expect(user.email, MockAuthRepository.demoEmail);
    expect(storage.access, isNotNull);
    expect((await repository.restoreSession())?.email, user.email);
  });

  test('refuse un mauvais mot de passe', () async {
    await expectLater(
      repository.login(MockAuthRepository.demoEmail, 'faux'),
      throwsA(isA<ApiException>()),
    );
    expect(storage.access, isNull);
  });

  test('inscription : compte créé sans connexion automatique', () async {
    await repository.register(nouveau);
    expect(storage.access, isNull);

    final user = await repository.login(nouveau.email, nouveau.password);
    expect(user.role, UserRole.acheteur);
  });

  test('refuse un email déjà utilisé', () async {
    await repository.register(nouveau);

    await expectLater(
      repository.register(nouveau),
      throwsA(
        isA<ApiException>().having(
          (e) => e.fieldErrors,
          'fieldErrors',
          contains('email'),
        ),
      ),
    );
  });

  test('la déconnexion efface la session', () async {
    await repository.login(
      MockAuthRepository.demoEmail,
      MockAuthRepository.demoPassword,
    );
    await repository.logout();

    expect(await repository.restoreSession(), isNull);
  });
}
