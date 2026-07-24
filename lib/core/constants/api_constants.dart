class ApiConstants {
  static const baseUrl = 'http://10.0.2.2:8000/api/v1';
  static const timeout = Duration(seconds: 30);

  // Auth
  static const register = '/auth/register';
  static const login = '/auth/login';
  static const refresh = '/auth/refresh';

  // Users
  static const usersMe = '/users/me';
  static const usersById = '/users/{}';
  static const userStamps = '/users/{}/stamps';
  static const userFollowers = '/users/{}/followers';
  static const userFollowing = '/users/{}/following';

  // Stamps
  static const stamps = '/stamps';
  static const stampById = '/stamps/{}';
  static const stampLike = '/stamps/{}/like';
  static const stampComments = '/stamps/{}/comments';

  // Feed
  static const feedPublic = '/feed/public';
  static const feedFollowing = '/feed/following';

  // Collections
  static const collections = '/collections';
  static const collectionById = '/collections/{}';
}
