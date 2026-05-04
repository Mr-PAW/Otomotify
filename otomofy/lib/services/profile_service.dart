import 'package:shared_preferences/shared_preferences.dart';

/// Handles local profile picture storage.
/// The picture itself is stored in the app's documents directory;
/// only the file path is persisted here via SharedPreferences.
class ProfileService {
  static String _picKey(String userId) => 'profile_pic_$userId';

  /// Save the local file path of the profile picture for [userId].
  static Future<void> saveProfilePicPath(String userId, String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_picKey(userId), path);
  }

  /// Retrieve the stored local path of the profile picture, or null.
  static Future<String?> getProfilePicPath(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_picKey(userId));
  }

  /// Remove the stored profile picture path (e.g. on logout or deletion).
  static Future<void> removeProfilePic(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_picKey(userId));
  }
}
