// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$publicFeedHash() => r'fbd33e10cbe88fcb3a5a6c6e15ba13dfd9d2d3cc';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$PublicFeed
    extends BuildlessAutoDisposeAsyncNotifier<List<StampCard>> {
  late final String sort;

  FutureOr<List<StampCard>> build({required String sort});
}

/// See also [PublicFeed].
@ProviderFor(PublicFeed)
const publicFeedProvider = PublicFeedFamily();

/// See also [PublicFeed].
class PublicFeedFamily extends Family<AsyncValue<List<StampCard>>> {
  /// See also [PublicFeed].
  const PublicFeedFamily();

  /// See also [PublicFeed].
  PublicFeedProvider call({required String sort}) {
    return PublicFeedProvider(sort: sort);
  }

  @override
  PublicFeedProvider getProviderOverride(
    covariant PublicFeedProvider provider,
  ) {
    return call(sort: provider.sort);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'publicFeedProvider';
}

/// See also [PublicFeed].
class PublicFeedProvider
    extends AutoDisposeAsyncNotifierProviderImpl<PublicFeed, List<StampCard>> {
  /// See also [PublicFeed].
  PublicFeedProvider({required String sort})
    : this._internal(
        () => PublicFeed()..sort = sort,
        from: publicFeedProvider,
        name: r'publicFeedProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$publicFeedHash,
        dependencies: PublicFeedFamily._dependencies,
        allTransitiveDependencies: PublicFeedFamily._allTransitiveDependencies,
        sort: sort,
      );

  PublicFeedProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.sort,
  }) : super.internal();

  final String sort;

  @override
  FutureOr<List<StampCard>> runNotifierBuild(covariant PublicFeed notifier) {
    return notifier.build(sort: sort);
  }

  @override
  Override overrideWith(PublicFeed Function() create) {
    return ProviderOverride(
      origin: this,
      override: PublicFeedProvider._internal(
        () => create()..sort = sort,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        sort: sort,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<PublicFeed, List<StampCard>>
  createElement() {
    return _PublicFeedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PublicFeedProvider && other.sort == sort;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, sort.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PublicFeedRef on AutoDisposeAsyncNotifierProviderRef<List<StampCard>> {
  /// The parameter `sort` of this provider.
  String get sort;
}

class _PublicFeedProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<PublicFeed, List<StampCard>>
    with PublicFeedRef {
  _PublicFeedProviderElement(super.provider);

  @override
  String get sort => (origin as PublicFeedProvider).sort;
}

String _$followingFeedHash() => r'29bcd516fb7338106245c641afdd9a149911ae56';

/// See also [FollowingFeed].
@ProviderFor(FollowingFeed)
final followingFeedProvider =
    AutoDisposeAsyncNotifierProvider<FollowingFeed, List<StampCard>>.internal(
      FollowingFeed.new,
      name: r'followingFeedProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$followingFeedHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FollowingFeed = AutoDisposeAsyncNotifier<List<StampCard>>;
String _$stampCommentsHash() => r'42f0000c6da7468193e8c2aa24b22be6c057b7ba';

abstract class _$StampComments
    extends BuildlessAutoDisposeAsyncNotifier<List<FeedComment>> {
  late final String stampId;

  FutureOr<List<FeedComment>> build({required String stampId});
}

/// See also [StampComments].
@ProviderFor(StampComments)
const stampCommentsProvider = StampCommentsFamily();

/// See also [StampComments].
class StampCommentsFamily extends Family<AsyncValue<List<FeedComment>>> {
  /// See also [StampComments].
  const StampCommentsFamily();

  /// See also [StampComments].
  StampCommentsProvider call({required String stampId}) {
    return StampCommentsProvider(stampId: stampId);
  }

  @override
  StampCommentsProvider getProviderOverride(
    covariant StampCommentsProvider provider,
  ) {
    return call(stampId: provider.stampId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'stampCommentsProvider';
}

/// See also [StampComments].
class StampCommentsProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<StampComments, List<FeedComment>> {
  /// See also [StampComments].
  StampCommentsProvider({required String stampId})
    : this._internal(
        () => StampComments()..stampId = stampId,
        from: stampCommentsProvider,
        name: r'stampCommentsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$stampCommentsHash,
        dependencies: StampCommentsFamily._dependencies,
        allTransitiveDependencies:
            StampCommentsFamily._allTransitiveDependencies,
        stampId: stampId,
      );

  StampCommentsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.stampId,
  }) : super.internal();

  final String stampId;

  @override
  FutureOr<List<FeedComment>> runNotifierBuild(
    covariant StampComments notifier,
  ) {
    return notifier.build(stampId: stampId);
  }

  @override
  Override overrideWith(StampComments Function() create) {
    return ProviderOverride(
      origin: this,
      override: StampCommentsProvider._internal(
        () => create()..stampId = stampId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        stampId: stampId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<StampComments, List<FeedComment>>
  createElement() {
    return _StampCommentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StampCommentsProvider && other.stampId == stampId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, stampId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StampCommentsRef
    on AutoDisposeAsyncNotifierProviderRef<List<FeedComment>> {
  /// The parameter `stampId` of this provider.
  String get stampId;
}

class _StampCommentsProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          StampComments,
          List<FeedComment>
        >
    with StampCommentsRef {
  _StampCommentsProviderElement(super.provider);

  @override
  String get stampId => (origin as StampCommentsProvider).stampId;
}

String _$stampActionHash() => r'8a22d9b52e31f19edc1dee45afca5ab4e0e2ebbe';

/// See also [StampAction].
@ProviderFor(StampAction)
final stampActionProvider =
    AutoDisposeNotifierProvider<StampAction, void>.internal(
      StampAction.new,
      name: r'stampActionProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$stampActionHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StampAction = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
