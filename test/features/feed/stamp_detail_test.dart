import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stampshunter/features/feed/domain/repositories/feed_repository.dart';
import 'package:stampshunter/features/feed/presentation/providers/feed_provider.dart';
import 'package:stampshunter/features/feed/presentation/screens/stamp_detail_screen.dart';
import 'package:stampshunter/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:stampshunter/features/profile/domain/entities/user_profile.dart';
import 'package:stampshunter/features/profile/presentation/providers/profile_provider.dart';
import 'package:stampshunter/features/stamp/domain/entities/stamp.dart';
import 'package:stampshunter/features/stamp/domain/repositories/stamp_repository.dart';
import 'package:stampshunter/features/stamp/presentation/providers/stamp_editor_provider.dart';
import 'package:stampshunter/features/onboarding/presentation/providers/onboarding_provider.dart';

class MockStampRepository extends Mock implements StampRepository {}
class MockProfileRepository extends Mock implements ProfileRepositoryImpl {}
class MockFeedRepository extends Mock implements FeedRepository {}

void main() {
  late MockStampRepository mockStampRepository;
  late MockProfileRepository mockProfileRepository;
  late MockFeedRepository mockFeedRepository;
  late SharedPreferences sharedPreferences;

  setUp(() async {
    mockStampRepository = MockStampRepository();
    mockProfileRepository = MockProfileRepository();
    mockFeedRepository = MockFeedRepository();
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
  });

  Widget createStampDetailWidget(String stampId, {required GoRouter router}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        stampRepositoryProvider.overrideWithValue(mockStampRepository),
        profileRepositoryProvider.overrideWithValue(mockProfileRepository),
        feedRepositoryProvider.overrideWithValue(mockFeedRepository),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('StampDetailScreen Widget Tests', () {
    testWidgets('should render full stamp details and author information', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      final dummyStamp = Stamp(
        id: 'stamp-999',
        userId: 'user-777',
        title: 'Borobudur Heritage',
        description: 'A beautiful retro look of Borobudur temple.',
        likesCount: 42,
        commentsCount: 7,
        createdAt: DateTime.now(),
        tags: ['temple', 'heritage'],
        stampImageUrl: 'http://img.png',
      );

      final dummyAuthor = UserProfile(
        id: 'user-777',
        username: 'indonesia_traveler',
        displayName: 'Indo Traveler',
        email: 'traveler@example.com',
        createdAt: DateTime.now(),
        stampsCount: 5,
        followersCount: 10,
        followingCount: 15,
      );

      when(() => mockStampRepository.getStamp('stamp-999'))
          .thenAnswer((_) async => dummyStamp);

      when(() => mockProfileRepository.getUserProfile('user-777'))
          .thenAnswer((_) async => dummyAuthor);

      when(() => mockFeedRepository.getPublicFeed(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            sort: any(named: 'sort'),
          )).thenAnswer((_) async => []);

      when(() => mockFeedRepository.getFollowingFeed(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => []);

      final router = GoRouter(
        initialLocation: '/stamp/stamp-999',
        routes: [
          GoRoute(
            path: '/stamp/:stampId',
            builder: (context, state) => StampDetailScreen(
              stampId: state.pathParameters['stampId']!,
            ),
          ),
        ],
      );

      await tester.pumpWidget(createStampDetailWidget('stamp-999', router: router));
      await tester.pump(); // Start fetching stamp
      await tester.pump(Duration.zero); // Resolve getStamp future
      await tester.pump(); // Rebuild to trigger getUserProfile
      await tester.pump(Duration.zero); // Resolve getUserProfile future
      await tester.pump(); // Rebuild with all data

      expect(find.text('BOROBUDUR HERITAGE'), findsOneWidget);
      expect(find.text('A beautiful retro look of Borobudur temple.'), findsOneWidget);
      expect(find.text('Indo Traveler'), findsOneWidget);
      expect(find.text('@indonesia_traveler'), findsOneWidget);
      expect(find.text('42 Likes'), findsOneWidget);
      expect(find.text('7 Komentar'), findsOneWidget);
      expect(find.text('#temple'), findsOneWidget);
      expect(find.text('#heritage'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });
  });
}
