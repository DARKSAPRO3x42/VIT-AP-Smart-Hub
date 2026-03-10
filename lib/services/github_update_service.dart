import 'dart:io';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class GitHubUpdateService {
  static const String repoOwner = 'DARKSAPRO3x42';
  static const String repoName = 'VIT-AP-Smart-Hub';
  static const String apiUrl = 'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';

  final Dio _dio = Dio();

  /// Checks if a newer version is available on GitHub
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await _dio.get(apiUrl);
      if (response.statusCode == 200) {
        final data = response.data;
        final String latestVersionTag = data['tag_name'];
        final String latestVersion = latestVersionTag.replaceAll('v', '');
        
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        if (_isNewerVersion(currentVersion, latestVersion)) {
          final assets = data['assets'] as List;
          if (assets.isNotEmpty) {
            final apkAsset = assets.firstWhere(
              (asset) => asset['name'].toString().endsWith('.apk'), 
              orElse: () => null
            );
            
            if (apkAsset != null) {
              return UpdateInfo(
                version: latestVersion,
                downloadUrl: apkAsset['browser_download_url'],
              );
            }
          }
        }
      }
    } catch (e) {
      print('Error checking for update: $e');
    }
    return null;
  }

  bool _isNewerVersion(String currentVersion, String latestVersion) {
    final List<String> currentParts = currentVersion.split('.');
    final List<String> latestParts = latestVersion.split('.');

    for (int i = 0; i < currentParts.length && i < latestParts.length; i++) {
      final int current = int.tryParse(currentParts[i]) ?? 0;
      final int latest = int.tryParse(latestParts[i]) ?? 0;
      if (latest > current) return true;
      if (latest < current) return false;
    }
    return latestParts.length > currentParts.length;
  }

  /// Downloads the APK and prompts to install it
  Future<void> downloadAndInstallUpdate(String downloadUrl, Function(double) onProgress) async {
    try {
      // Use temporary directory as it doesn't strictly need storage permissions
      // But OpenFile requires a file accessible to external intent, getExternalStorageDirectory is better for Android
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      
      if (directory == null) throw Exception("Could not find directory to save APK");

      final filePath = '${directory.path}/app-update.apk';
      final file = File(filePath);

      // Delete if already exists
      if (await file.exists()) {
        await file.delete();
      }

      await _dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );

      // Open the downloaded APK to trigger the installer
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        print('Error open file: ${result.message}');
      }
    } catch (e) {
      print('Error downloading update: $e');
      rethrow;
    }
  }
}

class UpdateInfo {
  final String version;
  final String downloadUrl;

  UpdateInfo({required this.version, required this.downloadUrl});
}
