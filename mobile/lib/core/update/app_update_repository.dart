import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../network/api_client.dart';
import 'app_version_model.dart';

class AppUpdateRepository {
  AppUpdateRepository(this._dio);

  final Dio _dio;

  /// Checks if a newer version is available for the current platform.
  ///
  /// Compares [PackageInfo.buildNumber] (versionCode) against the API's
  /// latest [AppVersionInfo.versionCode]. Returns [UpdateCheckResult].
  Future<UpdateCheckResult> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 1;
      final platform = Platform.isIOS ? 'ios' : 'android';

      final response = await _dio.get<Map<String, dynamic>>(
        '/app/version',
        queryParameters: {'platform': platform},
      );

      if (response.statusCode != 200 || response.data == null) {
        return const UpdateCheckResult(status: UpdateStatus.unavailable);
      }

      final latest = AppVersionInfo.fromJson(response.data!);

      if (latest.versionCode <= currentVersionCode) {
        return const UpdateCheckResult(status: UpdateStatus.upToDate);
      }

      return UpdateCheckResult(
        status: latest.isMandatory
            ? UpdateStatus.mandatoryUpdate
            : UpdateStatus.updateAvailable,
        latestVersion: latest,
      );
    } on DioException catch (e) {
      // 404 means no version published yet — treat as up to date.
      if (e.response?.statusCode == 404) {
        return const UpdateCheckResult(status: UpdateStatus.upToDate);
      }
      debugPrint('[AppUpdate] Check failed: $e');
      return const UpdateCheckResult(status: UpdateStatus.unavailable);
    } catch (e) {
      debugPrint('[AppUpdate] Unexpected error: $e');
      return const UpdateCheckResult(status: UpdateStatus.unavailable);
    }
  }

  /// Downloads the APK from [downloadUrl] to the app's temp directory.
  ///
  /// [onProgress] is called with values 0.0–1.0 as download progresses.
  /// Returns the local file path when done, or throws on error.
  Future<String> downloadApk(
    String downloadUrl, {
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final dir = await getTemporaryDirectory();
    // Extract filename from URL or use default.
    final fileName = downloadUrl.split('/').last.isNotEmpty
        ? downloadUrl.split('/').last
        : 'nina-dental-care-update.apk';
    final savePath = '${dir.path}/$fileName';

    // Remove old APK file if it exists
    final file = File(savePath);
    if (await file.exists()) await file.delete();

    await _dio.download(
      downloadUrl,
      savePath,
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        if (total > 0 && onProgress != null) {
          onProgress(received / total);
        }
      },
    );

    return savePath;
  }

  /// Requests the INSTALL_PACKAGES permission (Android) and triggers APK install.
  /// Returns true if install was triggered, false if permission was denied.
  Future<bool> installApk(String filePath) async {
    if (Platform.isAndroid) {
      // Android 8+ requires REQUEST_INSTALL_PACKAGES permission
      final status = await Permission.requestInstallPackages.status;
      if (!status.isGranted) {
        final result = await Permission.requestInstallPackages.request();
        if (!result.isGranted) {
          return false;
        }
      }
    }

    final result = await OpenFilex.open(
      filePath,
      type: 'application/vnd.android.package-archive',
    );

    debugPrint('[AppUpdate] OpenFilex result: ${result.type} - ${result.message}');
    return result.type == ResultType.done;
  }
}

final appUpdateRepositoryProvider = Provider<AppUpdateRepository>((ref) {
  return AppUpdateRepository(ref.watch(dioProvider));
});
