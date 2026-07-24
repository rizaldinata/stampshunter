import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stampshunter/app/theme/app_colors.dart';
import 'package:stampshunter/features/camera/presentation/providers/stamp_image_picker_provider.dart';
import 'package:stampshunter/features/camera/presentation/widgets/source_picker_sheet.dart';
import 'package:stampshunter/features/feed/domain/entities/stamp_card.dart';
import 'package:stampshunter/features/feed/presentation/providers/feed_provider.dart';
import 'package:stampshunter/features/feed/presentation/widgets/stamp_card.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _publicSort = 'trending'; // trending or recent

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDarkTheme : AppColors.primary;
    final bg = isDark ? AppColors.surfaceDark : const Color(0xFFFFFDF9);
    final indicatorColor = isDark ? AppColors.primaryDarkTheme : AppColors.primary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        title: Text(
          'StampsHunter',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.push('/profile/me'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: indicatorColor,
          unselectedLabelColor: isDark ? Colors.white60 : AppColors.textTertiary,
          indicatorColor: indicatorColor,
          indicatorWeight: 3.0,
          labelStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: 1.0,
          ),
          tabs: const [
            Tab(text: 'FOR YOU'),
            Tab(text: 'FOLLOWING'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: For You (Public Feed)
          _buildPublicFeedTab(),

          // Tab 2: Following Feed
          _buildFollowingFeedTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        shape: const CircleBorder(),
        onPressed: () async {
          final option = await SourcePickerSheet.show(context);
          if (option == null) return;

          if (option == ImageSourceOption.camera) {
            if (context.mounted) {
              context.push('/camera');
            }
          } else if (option == ImageSourceOption.gallery) {
            final notifier = ref.read(stampImagePickerProvider.notifier);
            final picked = await notifier.pickFromGallery();
            if (picked) {
              final state = ref.read(stampImagePickerProvider);
              if (state.selectedImagePath != null) {
                final cropped = await notifier.cropImage(state.selectedImagePath!);
                if (cropped != null && context.mounted) {
                  context.push('/stamp-editor', extra: cropped);
                }
              }
            }
          }
        },
        child: const Icon(Icons.add_a_photo_outlined),
      ),
    );
  }

  Widget _buildPublicFeedTab() {
    final publicFeedAsync = ref.watch(publicFeedProvider(sort: _publicSort));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Sort Filter Chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              _buildSortChip(
                label: 'TRENDING',
                value: 'trending',
              ),
              const SizedBox(width: 8),
              _buildSortChip(
                label: 'TERBARU',
                value: 'recent',
              ),
            ],
          ),
        ),
        Expanded(
          child: FeedList(
            asyncFeed: publicFeedAsync,
            onRefresh: () async {
              ref.invalidate(publicFeedProvider(sort: _publicSort));
            },
            onLoadMore: () async {
              await ref.read(publicFeedProvider(sort: _publicSort).notifier).loadMore();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFollowingFeedTab() {
    final followingFeedAsync = ref.watch(followingFeedProvider);

    return FeedList(
      asyncFeed: followingFeedAsync,
      onRefresh: () async {
        ref.invalidate(followingFeedProvider);
      },
      onLoadMore: () async {
        await ref.read(followingFeedProvider.notifier).loadMore();
      },
    );
  }

  Widget _buildSortChip({required String label, required String value}) {
    final isSelected = _publicSort == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.primaryDarkTheme : AppColors.primary;

    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.black : (isDark ? Colors.white70 : AppColors.textSecondary),
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _publicSort = value;
          });
        }
      },
      selectedColor: activeColor,
      backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
    );
  }
}

class FeedList extends StatefulWidget {
  final AsyncValue<List<StampCard>> asyncFeed;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;

  const FeedList({
    super.key,
    required this.asyncFeed,
    required this.onRefresh,
    required this.onLoadMore,
  });

  @override
  State<FeedList> createState() => _FeedListState();
}

class _FeedListState extends State<FeedList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return widget.asyncFeed.when(
      data: (stamps) {
        if (stamps.isEmpty) {
          return RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_frames_outlined,
                        size: 48,
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada stamp digital yang dibagikan.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: widget.onRefresh,
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: stamps.length + 1,
            itemBuilder: (context, index) {
              if (index < stamps.length) {
                return StampCardWidget(card: stamps[index]);
              }
              // Pagination bottom loader
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.withOpacity(0.6)),
                  const SizedBox(height: 12),
                  Text(
                    'Gagal memuat feed: ${error.toString()}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: widget.onRefresh,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
