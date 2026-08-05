import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_update_repository.dart';
import 'app_version_model.dart';

/// Riverpod state for the in-app update flow.
///
/// State machine:
///   idle → checking → [upToDate | updateAvailable | mandatoryUpdate | error]
///        → downloading(progress 0.0-1.0) → downloaded(path) → installing
sealed class UpdateState {
  const UpdateState();
}

class UpdateIdle extends UpdateState {
  const UpdateIdle();
}

class UpdateChecking extends UpdateState {
  const UpdateChecking();
}

class UpdateUpToDate extends UpdateState {
  const UpdateUpToDate();
}

class UpdateAvailable extends UpdateState {
  const UpdateAvailable({required this.info, required this.isMandatory});
  final AppVersionInfo info;
  final bool isMandatory;
}

class UpdateDownloading extends UpdateState {
  const UpdateDownloading({required this.progress, required this.info});
  final double progress; // 0.0 – 1.0
  final AppVersionInfo info;
}

class UpdateDownloaded extends UpdateState {
  const UpdateDownloaded({required this.filePath, required this.info});
  final String filePath;
  final AppVersionInfo info;
}

class UpdateInstalling extends UpdateState {
  const UpdateInstalling();
}

class UpdateError extends UpdateState {
  const UpdateError({required this.message});
  final String message;
}

// ---------------------------------------------------------------------------

class AppUpdateNotifier extends Notifier<UpdateState> {
  @override
  UpdateState build() => const UpdateIdle();

  AppUpdateRepository get _repo => ref.read(appUpdateRepositoryProvider);

  /// Checks for a new version against the API.
  /// Called automatically on app startup from [main.dart].
  Future<void> checkForUpdate() async {
    if (state is UpdateChecking || state is UpdateDownloading) return;
    state = const UpdateChecking();

    final result = await _repo.checkForUpdate();

    switch (result.status) {
      case UpdateStatus.upToDate:
      case UpdateStatus.unavailable:
        state = const UpdateUpToDate();
      case UpdateStatus.updateAvailable:
        state = UpdateAvailable(
          info: result.latestVersion!,
          isMandatory: false,
        );
      case UpdateStatus.mandatoryUpdate:
        state = UpdateAvailable(
          info: result.latestVersion!,
          isMandatory: true,
        );
    }
  }

  /// Downloads and installs the APK. Updates state with download progress.
  CancelToken? _cancelToken;

  Future<void> downloadAndInstall(AppVersionInfo info) async {
    _cancelToken = CancelToken();
    state = UpdateDownloading(progress: 0, info: info);

    try {
      final path = await _repo.downloadApk(
        info.downloadUrl,
        cancelToken: _cancelToken,
        onProgress: (progress) {
          state = UpdateDownloading(progress: progress, info: info);
        },
      );

      state = UpdateDownloaded(filePath: path, info: info);

      // Slight delay so user sees "Selesai" state before install dialog opens.
      await Future.delayed(const Duration(milliseconds: 400));

      state = const UpdateInstalling();
      final installed = await _repo.installApk(path);

      if (!installed) {
        state = UpdateError(
          message: 'Gagal membuka installer. Pastikan izin install aplikasi diaktifkan di Pengaturan.',
        );
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        state = UpdateAvailable(info: info, isMandatory: info.isMandatory);
      } else {
        state = UpdateError(message: 'Download gagal: ${e.message ?? 'Periksa koneksi internet Anda.'}');
      }
    } catch (e) {
      state = UpdateError(message: 'Terjadi kesalahan: $e');
    }
  }

  /// Cancel an in-progress download.
  void cancelDownload() {
    _cancelToken?.cancel('User cancelled');
    _cancelToken = null;
  }

  /// Reset error state so user can retry.
  void retry(AppVersionInfo info) {
    state = UpdateAvailable(info: info, isMandatory: info.isMandatory);
  }

  /// Dismiss an optional update (allowed only if !isMandatory).
  void dismiss() {
    state = const UpdateUpToDate();
  }
}

final appUpdateNotifierProvider =
    NotifierProvider<AppUpdateNotifier, UpdateState>(AppUpdateNotifier.new);
