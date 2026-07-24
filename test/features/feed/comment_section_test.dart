import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stampshunter/features/feed/domain/entities/feed_comment.dart';
import 'package:stampshunter/features/feed/domain/repositories/feed_repository.dart';
import 'package:stampshunter/features/feed/presentation/providers/feed_provider.dart';
import 'package:stampshunter/features/feed/presentation/widgets/comment_section.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

void main() {
  late MockFeedRepository mockFeedRepository;

  setUp(() {
    mockFeedRepository = MockFeedRepository();
  });

  Widget createCommentSectionWidget(String stampId) {
    return ProviderScope(
      overrides: [
        feedRepositoryProvider.overrideWithValue(mockFeedRepository),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: CommentSection(stampId: stampId),
        ),
      ),
    );
  }

  group('CommentSection Widget Tests', () {
    testWidgets('should render empty state message when there are no comments', (WidgetTester tester) async {
      when(() => mockFeedRepository.getComments(
            'stamp-123',
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => []);

      await tester.pumpWidget(createCommentSectionWidget('stamp-123'));
      await tester.pump();
      await tester.pump(Duration.zero);
      await tester.pump();

      expect(find.text('Belum ada komentar.\nJadilah yang pertama berkomentar!'), findsOneWidget);
    });

    testWidgets('should render comments list correctly when data is present', (WidgetTester tester) async {
      final mockComments = [
        FeedComment(
          id: 'comment-1',
          userId: 'user-777',
          username: 'retro_lover',
          content: 'This stamp design is fantastic!',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ];

      when(() => mockFeedRepository.getComments(
            'stamp-123',
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => mockComments);

      await tester.pumpWidget(createCommentSectionWidget('stamp-123'));
      await tester.pump();
      await tester.pump(Duration.zero);
      await tester.pump();

      expect(find.text('@retro_lover'), findsOneWidget);
      expect(find.text('This stamp design is fantastic!'), findsOneWidget);
      expect(find.text('5m ago'), findsOneWidget);
    });

    testWidgets('should call addComment when submit button is tapped with text input', (WidgetTester tester) async {
      when(() => mockFeedRepository.getComments(
            'stamp-123',
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => []);

      final dummyNewComment = FeedComment(
        id: 'comment-new',
        userId: 'user-me',
        username: 'me',
        content: 'I want this stamp!',
        createdAt: DateTime.now(),
      );

      when(() => mockFeedRepository.addComment(
            'stamp-123',
            content: 'I want this stamp!',
            parentId: any(named: 'parentId'),
          )).thenAnswer((_) async => dummyNewComment);

      await tester.pumpWidget(createCommentSectionWidget('stamp-123'));
      await tester.pump();
      await tester.pump(Duration.zero);
      await tester.pump();

      final textfield = find.byType(TextField);
      expect(textfield, findsOneWidget);

      await tester.enterText(textfield, 'I want this stamp!');
      await tester.pump();

      final sendButton = find.byIcon(Icons.send_rounded);
      expect(sendButton, findsOneWidget);

      await tester.tap(sendButton);
      await tester.pump(); // Start submitting
      await tester.pump(Duration.zero); // Resolve addComment future
      await tester.pump(); // Rebuild state

      verify(() => mockFeedRepository.addComment(
            'stamp-123',
            content: 'I want this stamp!',
            parentId: any(named: 'parentId'),
          )).called(1);
    });
  });
}
