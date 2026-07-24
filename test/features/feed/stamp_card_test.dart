import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stampshunter/features/feed/domain/entities/stamp_card.dart';
import 'package:stampshunter/features/feed/domain/repositories/feed_repository.dart';
import 'package:stampshunter/features/feed/presentation/providers/feed_provider.dart';
import 'package:stampshunter/features/feed/presentation/widgets/stamp_card.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

void main() {
  late MockFeedRepository mockFeedRepository;

  setUp(() {
    mockFeedRepository = MockFeedRepository();
  });

  Widget createStampCardWidget(StampCard card, {required GoRouter router}) {
    return ProviderScope(
      overrides: [
        feedRepositoryProvider.overrideWithValue(mockFeedRepository),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('StampCardWidget Tests', () {
    testWidgets('should render stamp details correctly', (WidgetTester tester) async {
      // Set larger viewport to prevent overflow issues
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      final card = StampCard(
        id: 'stamp-123',
        userId: 'user-456',
        username: 'collector_guru',
        displayName: 'Collector Guru',
        title: 'Rare Heritage Stamp',
        likesCount: 150,
        commentsCount: 22,
        isLiked: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: ListView(
                children: [StampCardWidget(card: card)],
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(createStampCardWidget(card, router: router));
      await tester.pumpAndSettle();

      expect(find.text('RARE HERITAGE STAMP'), findsOneWidget);
      expect(find.text('@collector_guru'), findsOneWidget);
      expect(find.text('Collector Guru'), findsOneWidget);
      expect(find.text('150'), findsOneWidget);
      expect(find.text('2j yang lalu'), findsOneWidget);

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('should call toggleLike repository method when like is tapped', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      final card = StampCard(
        id: 'stamp-123',
        userId: 'user-456',
        username: 'collector_guru',
        title: 'Rare Heritage Stamp',
        likesCount: 100,
        isLiked: false,
        createdAt: DateTime.now(),
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: ListView(
                children: [StampCardWidget(card: card)],
              ),
            ),
          ),
        ],
      );

      when(() => mockFeedRepository.toggleLike('stamp-123'))
          .thenAnswer((_) async => {'is_liked': true, 'likes_count': 101});

      await tester.pumpWidget(createStampCardWidget(card, router: router));
      await tester.pumpAndSettle();

      final likeButton = find.byIcon(Icons.favorite_border_rounded);
      expect(likeButton, findsOneWidget);

      await tester.tap(likeButton);
      await tester.pump(); // Start toggle action
      await tester.pump(Duration.zero); // Resolve toggleLike future

      verify(() => mockFeedRepository.toggleLike('stamp-123')).called(1);

      await tester.binding.setSurfaceSize(null);
    });
  });
}
