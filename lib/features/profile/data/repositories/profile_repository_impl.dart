import 'package:stampshunter/features/profile/domain/entities/user_profile.dart';
import 'package:stampshunter/features/profile/domain/repositories/profile_repository.dart';
import 'package:stampshunter/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:stampshunter/features/stamp/domain/entities/stamp.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserProfile> getMe(String token) {
    return remoteDataSource.getMe(token);
  }

  @override
  Future<UserProfile> getUserProfile(String userId) {
    return remoteDataSource.getUserProfile(userId);
  }

  @override
  Future<UserProfile> updateUserProfile({
    required String token,
    String? displayName,
    String? bio,
    List<int>? avatarBytes,
    String? avatarFilename,
  }) {
    return remoteDataSource.updateUserProfile(
      token: token,
      displayName: displayName,
      bio: bio,
      avatarBytes: avatarBytes,
      avatarFilename: avatarFilename,
    );
  }

  @override
  Future<List<Stamp>> getUserStamps({
    required String userId,
    int page = 1,
    int limit = 20,
  }) {
    return remoteDataSource.getUserStamps(
      userId: userId,
      page: page,
      limit: limit,
    );
  }
}
