import 'package:stampshunter/features/profile/domain/entities/user_profile.dart';
import 'package:stampshunter/features/stamp/domain/entities/stamp.dart';

abstract class ProfileRepository {
  Future<UserProfile> getMe(String token);
  Future<UserProfile> getUserProfile(String userId);
  Future<UserProfile> updateUserProfile({
    required String token,
    String? displayName,
    String? bio,
    List<int>? avatarBytes,
    String? avatarFilename,
  });
  Future<List<Stamp>> getUserStamps({
    required String userId,
    int page = 1,
    int limit = 20,
  });
}
