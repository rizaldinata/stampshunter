import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampshunter/features/auth/presentation/providers/auth_provider.dart';
import 'package:stampshunter/features/profile/domain/entities/user_profile.dart';
import 'package:stampshunter/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:stampshunter/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:stampshunter/features/stamp/domain/entities/stamp.dart';
import 'package:stampshunter/core/errors/exceptions.dart';

// --- Data Layer Providers ---

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSource(dio: ref.watch(dioProvider));
});

final profileRepositoryProvider = Provider<ProfileRepositoryImpl>((ref) {
  return ProfileRepositoryImpl(
    remoteDataSource: ref.watch(profileRemoteDataSourceProvider),
  );
});

// --- Profile Provider Family ---

final profileProvider = FutureProvider.family<UserProfile, String>((ref, userId) async {
  final repository = ref.watch(profileRepositoryProvider);
  final authState = ref.watch(authProvider);

  if (userId == 'me' || (authState.user != null && userId == authState.user!.id)) {
    final token = authState.accessToken;
    if (token == null) {
      throw AppException(code: 'AUTH_ERROR', message: 'Silakan login terlebih dahulu');
    }
    return repository.getMe(token);
  } else {
    return repository.getUserProfile(userId);
  }
});

// --- User Stamps Provider Family ---

final userStampsProvider = FutureProvider.family<List<Stamp>, String>((ref, userId) async {
  final repository = ref.watch(profileRepositoryProvider);
  
  // Resolve 'me' to actual user ID if needed
  String resolvedId = userId;
  if (userId == 'me') {
    final authState = ref.watch(authProvider);
    if (authState.user == null) {
      throw AppException(code: 'AUTH_ERROR', message: 'Silakan login terlebih dahulu');
    }
    resolvedId = authState.user!.id;
  }
  
  return repository.getUserStamps(userId: resolvedId, page: 1, limit: 100);
});

// --- Edit Profile State & Notifier ---

class EditProfileState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const EditProfileState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  EditProfileState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return EditProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class EditProfileNotifier extends StateNotifier<EditProfileState> {
  final ProfileRepositoryImpl _repository;
  final Ref _ref;

  EditProfileNotifier(this._repository, this._ref) : super(const EditProfileState());

  Future<void> updateProfile({
    required String displayName,
    required String bio,
    List<int>? avatarBytes,
    String? avatarFilename,
  }) async {
    state = const EditProfileState(isLoading: true);
    try {
      final authState = _ref.read(authProvider);
      final token = authState.accessToken;
      if (token == null) {
        throw AppException(code: 'AUTH_ERROR', message: 'Sesi habis. Silakan login kembali.');
      }

      final updatedProfile = await _repository.updateUserProfile(
        token: token,
        displayName: displayName,
        bio: bio,
        avatarBytes: avatarBytes,
        avatarFilename: avatarFilename,
      );

      // Invalidate target profile providers so UI is refreshed instantly
      _ref.invalidate(profileProvider('me'));
      if (authState.user != null) {
        _ref.invalidate(profileProvider(authState.user!.id));
        
        // Also update local auth user details to match updated profile
        final updatedUser = authState.user!.copyWith(
          displayName: updatedProfile.displayName,
          bio: updatedProfile.bio,
          avatarUrl: updatedProfile.avatarUrl,
        );
        _ref.read(authProvider.notifier).updateUser(updatedUser);
      }

      state = const EditProfileState(isSuccess: true);
    } on AppException catch (e) {
      state = EditProfileState(error: e.userMessage);
    } catch (e) {
      state = const EditProfileState(error: 'Gagal memperbarui profil. Coba lagi.');
    }
  }

  void reset() {
    state = const EditProfileState();
  }
}

final editProfileProvider = StateNotifierProvider<EditProfileNotifier, EditProfileState>((ref) {
  return EditProfileNotifier(ref.watch(profileRepositoryProvider), ref);
});
