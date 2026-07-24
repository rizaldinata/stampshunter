import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stampshunter/features/feed/domain/entities/stamp_card.dart';
import 'package:stampshunter/features/feed/domain/repositories/feed_repository.dart';
import 'package:stampshunter/features/feed/presentation/providers/feed_provider.dart';
import 'package:stampshunter/features/feed/presentation/screens/feed_screen.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

void main() {
  late MockFeedRepository mockFeedRepository;

  setUp(() {
    mockFeedRepository = MockFeedRepository();
  });

  Widget createFeedScreenWidget() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const FeedScreen(),
        ),
        GoRoute(
          path: '/profile/:userId',
          builder: (context, state) => const Scaffold(body: Text('Profile Page')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        feedRepositoryProvider.overrideWithValue(mockFeedRepository),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('FeedScreen Widget Tests', () {
    testWidgets('should render tab bar options and header', (WidgetTester tester) async {
      when(() => mockFeedRepository.getPublicFeed(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            sort: any(named: 'sort'),
          )).thenAnswer((_) async => []);

      when(() => mockFeedRepository.getFollowingFeed(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => []);

      await tester.pumpWidget(createFeedScreenWidget());
      await tester.pumpAndSettle();

      expect(find.text('StampsHunter'), findsOneWidget);
      expect(find.text('FOR YOU'), findsOneWidget);
      expect(find.text('FOLLOWING'), findsOneWidget);
    });

    testWidgets('should show empty state message if feed has no stamps', (WidgetTester tester) async {
      when(() => mockFeedRepository.getPublicFeed(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            sort: any(named: 'sort'),
          )).thenAnswer((_) async => []);

      when(() => mockFeedRepository.getFollowingFeed(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => []);

      await tester.pumpWidget(createFeedScreenWidget());
      await tester.pump(); // initial load (loading state)
      await tester.pump(Duration.zero); // resolve futures
      await tester.pump(); // build data/empty state

      expect(find.text('Belum ada stamp digital yang dibagikan.'), findsOneWidget);
    });

    testWidgets('should render list of stamp cards when data is present', (WidgetTester tester) async {
      final mockStamps = [
        StampCard(
          id: 'stamp-1',
          userId: 'user-1',
          username: 'creator_1',
          displayName: 'Creator One',
          title: 'First Vintage Stamp',
          likesCount: 12,
          commentsCount: 3,
          isLiked: false,
          createdAt: DateTime.now(),
        ),
      ];

      when(() => mockFeedRepository.getPublicFeed(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            sort: any(named: 'sort'),
          )).thenAnswer((_) async => mockStamps);

      when(() => mockFeedRepository.getFollowingFeed(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => []);

      await tester.pumpWidget(createFeedScreenWidget());
      await tester.pump(); // initial build (loading state)
      await tester.pump(Duration.zero); // resolve future
      await tester.pump(); // rebuild with data

      expect(find.text('FIRST VINTAGE STAMP'), findsOneWidget);
      expect(find.text('@creator_1'), findsOneWidget);
    });
  });
}
