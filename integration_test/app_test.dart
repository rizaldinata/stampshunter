import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stampshunter/app/app.dart';
import 'package:stampshunter/features/auth/domain/repositories/auth_repository.dart';
import 'package:stampshunter/features/auth/domain/entities/user.dart';
import 'package:stampshunter/features/auth/presentation/providers/auth_provider.dart';
import 'package:stampshunter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:stampshunter/features/feed/domain/repositories/feed_repository.dart';
import 'package:stampshunter/features/feed/domain/entities/stamp_card.dart';
import 'package:stampshunter/features/feed/presentation/providers/feed_provider.dart';
import 'package:stampshunter/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:stampshunter/features/stamp/domain/entities/stamp.dart';
import 'package:stampshunter/features/stamp/domain/repositories/stamp_repository.dart';
import 'package:stampshunter/features/stamp/presentation/providers/stamp_editor_provider.dart';
import 'package:stampshunter/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:stampshunter/features/profile/domain/entities/user_profile.dart';
import 'package:stampshunter/features/profile/presentation/providers/profile_provider.dart';

class MockAuthRepository extends Mock implements AuthRepositoryImpl {}
class MockFeedRepository extends Mock implements FeedRepository {}
class MockStampRepository extends Mock implements StampRepository {}
class MockProfileRepository extends Mock implements ProfileRepositoryImpl {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository mockAuthRepository;
  late MockFeedRepository mockFeedRepository;
  late MockStampRepository mockStampRepository;
  late MockProfileRepository mockProfileRepository;
  late SharedPreferences sharedPreferences;

  setUp(() async {
    mockAuthRepository = MockAuthRepository();
    mockFeedRepository = MockFeedRepository();
    mockStampRepository = MockStampRepository();
    mockProfileRepository = MockProfileRepository();
    
    // Eager set preferences so we skip onboarding and directly show login
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding': true,
    });
    sharedPreferences = await SharedPreferences.getInstance();
  });

  testWidgets('End-to-End User Flow Integration Test', (WidgetTester tester) async {
    // Set viewport size
    await tester.binding.setSurfaceSize(const Size(800, 1200));

    final dummyUser = User(
      id: 'user-123',
      username: 'test_collector',
      email: 'test@example.com',
      displayName: 'Test Collector',
      createdAt: DateTime.now(),
    );

    final dummyAuthResult = AuthResult(
      user: dummyUser,
      accessToken: 'dummy-access-token',
      refreshToken: 'dummy-refresh-token',
    );

    final dummyStampCard = StampCard(
      id: 'stamp-111',
      userId: 'user-456',
      username: 'ancient_hunter',
      displayName: 'Ancient Hunter',
      title: 'Majapahit Stamp',
      likesCount: 99,
      commentsCount: 15,
      isLiked: false,
      createdAt: DateTime.now(),
    );

    final dummyStampDetails = Stamp(
      id: 'stamp-111',
      userId: 'user-456',
      title: 'Majapahit Stamp',
      description: 'Stamps commemorating the Majapahit Empire.',
      likesCount: 99,
      commentsCount: 15,
      createdAt: DateTime.now(),
      tags: ['history', 'indonesia'],
    );

    final dummyAuthorProfile = UserProfile(
      id: 'user-456',
      username: 'ancient_hunter',
      displayName: 'Ancient Hunter',
      email: 'hunter@example.com',
      createdAt: DateTime.now(),
      stampsCount: 20,
      followersCount: 100,
      followingCount: 50,
    );

    // Setup stubbing
    when(() => mockAuthRepository.getCurrentUser()).thenAnswer((_) async => null);
    when(() => mockAuthRepository.login(
          email: 'test@example.com',
          password: 'password123',
        )).thenAnswer((_) async => dummyAuthResult);

    when(() => mockFeedRepository.getPublicFeed(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          sort: any(named: 'sort'),
        )).thenAnswer((_) async => [dummyStampCard]);

    when(() => mockFeedRepository.getFollowingFeed(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => []);

    when(() => mockStampRepository.getStamp('stamp-111'))
        .thenAnswer((_) async => dummyStampDetails);

    when(() => mockProfileRepository.getUserProfile('user-456'))
        .thenAnswer((_) async => dummyAuthorProfile);

    // 1. Launch the app
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          feedRepositoryProvider.overrideWithValue(mockFeedRepository),
          stampRepositoryProvider.overrideWithValue(mockStampRepository),
          profileRepositoryProvider.overrideWithValue(mockProfileRepository),
        ],
        child: const StampsHunterApp(),
      ),
    );

    await tester.pump();
    await tester.pump(Duration.zero); // Resolve getCurrentUser (null session)
    await tester.pumpAndSettle(); // Settle transition to LoginScreen

    // 2. Verify we are on Login Screen
    expect(find.text('EMAIL'), findsOneWidget);
    expect(find.text('KATA SANDI'), findsOneWidget);

    // 3. Input email and password
    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(2));
    
    await tester.enterText(textFields.at(0), 'test@example.com');
    await tester.enterText(textFields.at(1), 'password123');
    await tester.pumpAndSettle();

    // 4. Tap "Masuk" (Buka Koleksi) button
    final loginButton = find.text('Buka Koleksi');
    expect(loginButton, findsOneWidget);
    await tester.tap(loginButton);
    await tester.pump(); // Starts login loading
    await tester.pump(Duration.zero); // Resolves login future
    await tester.pump(); // Trigger navigation
    await tester.pump(const Duration(milliseconds: 500)); // wait for route transition animation
    await tester.pump(Duration.zero); // resolve publicFeedProvider future
    await tester.pump(); // rebuild FeedScreen with loaded stamps

    // 5. Verify we are on Feed Screen
    expect(find.text('StampsHunter'), findsOneWidget);
    expect(find.text('MAJAPAHIT STAMP'), findsOneWidget);
    expect(find.text('@ancient_hunter'), findsOneWidget);

    // 6. Tap on stamp card image to open Stamp Detail screen
    final stampCardTapArea = find.byIcon(Icons.image_outlined);
    await tester.tap(stampCardTapArea);
    await tester.pump(); // Starts navigation
    await tester.pump(const Duration(milliseconds: 500)); // Wait for transition animation
    await tester.pump(Duration.zero); // Resolves getStamp future
    await tester.pump(); // Rebuild to trigger getUserProfile
    await tester.pump(Duration.zero); // Resolves getUserProfile future
    await tester.pump(); // Complete transition to StampDetailScreen

    // 7. Verify we are on Stamp Detail screen
    expect(find.text('DETAIL STAMP'), findsOneWidget);
    expect(find.text('MAJAPAHIT STAMP'), findsOneWidget);
    expect(find.text('Stamps commemorating the Majapahit Empire.'), findsOneWidget);
    expect(find.text('Ancient Hunter'), findsOneWidget);
    expect(find.text('99 Likes'), findsOneWidget);
    expect(find.text('15 Komentar'), findsOneWidget);

    // Reset surface size
    await tester.binding.setSurfaceSize(null);
  });
}
