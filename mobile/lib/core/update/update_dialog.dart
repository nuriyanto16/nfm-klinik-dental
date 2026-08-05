import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import 'app_update_notifier.dart';
import 'app_version_model.dart';

/// Shows the appropriate update dialog based on [UpdateState].
///
/// Call this from the app's root widget when you detect [UpdateAvailable].
/// Mandatory updates use a barrier-dismissible=false dialog that blocks
/// the user from using the app until the update is installed.
class UpdateDialog extends ConsumerWidget {
  const UpdateDialog({
    super.key,
    required this.info,
    required this.isMandatory,
  });

  final AppVersionInfo info;
  final bool isMandatory;

  static Future<void> show(
    BuildContext context, {
    required AppVersionInfo info,
    required bool isMandatory,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false, // Always false — handled inside via "Nanti"
      builder: (_) => UpdateDialog(info: info, isMandatory: isMandatory),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appUpdateNotifierProvider);

    return PopScope(
      // Block Android back button for mandatory updates
      canPop: !isMandatory,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: _buildContent(context, ref, state),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, UpdateState state) {
    return switch (state) {
      UpdateDownloading(:final progress, :final info) =>
        _DownloadingContent(progress: progress, info: info, isMandatory: isMandatory),
      UpdateDownloaded() => _DownloadedContent(info: info, isMandatory: isMandatory),
      UpdateInstalling() => _InstallingContent(),
      UpdateError(:final message) =>
        _ErrorContent(message: message, info: info, isMandatory: isMandatory),
      _ => _PromptContent(info: info, isMandatory: isMandatory),
    };
  }
}

// ---------------------------------------------------------------------------
// Prompt content — shows version info and update/dismiss buttons
// ---------------------------------------------------------------------------

class _PromptContent extends ConsumerWidget {
  const _PromptContent({required this.info, required this.isMandatory});

  final AppVersionInfo info;
  final bool isMandatory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isMandatory
                    ? [const Color(0xFFEC407A), const Color(0xFFD81B60)]
                    : [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isMandatory
                        ? Icons.system_security_update_warning_rounded
                        : Icons.system_update_alt_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isMandatory ? 'Update Wajib Tersedia' : 'Update Tersedia',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Versi ${info.versionName}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isMandatory) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Update ini wajib. Anda tidak dapat menggunakan aplikasi sebelum melakukan pembaruan.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const Text(
                  'Apa yang baru?',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    info.releaseNotes ??
                        '• Perbaikan tampilan dan font\n'
                            '• Halaman pembayaran lebih lengkap\n'
                            '• Promo & artikel dengan gambar menarik\n'
                            '• Performa lebih baik',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textDark,
                      height: 1.6,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Update button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Consumer(
                    builder: (ctx, ref, _) => FilledButton.icon(
                      onPressed: () => ref
                          .read(appUpdateNotifierProvider.notifier)
                          .downloadAndInstall(info),
                      icon: const Icon(Icons.download_rounded, size: 20),
                      label: const Text(
                        'Update Sekarang',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: isMandatory ? AppColors.pink : AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),

                if (!isMandatory) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ref.read(appUpdateNotifierProvider.notifier).dismiss();
                      },
                      child: const Text(
                        'Nanti Saja',
                        style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Downloading content — progress bar
// ---------------------------------------------------------------------------

class _DownloadingContent extends ConsumerWidget {
  const _DownloadingContent({
    required this.progress,
    required this.info,
    required this.isMandatory,
  });

  final double progress;
  final AppVersionInfo info;
  final bool isMandatory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final percent = (progress * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  color: AppColors.primary,
                  backgroundColor: const Color(0xFFE2E8F0),
                ),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Mengunduh Pembaruan...',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          Text(
            'Versi ${info.versionName} sedang diunduh',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              color: AppColors.primary,
              backgroundColor: const Color(0xFFE2E8F0),
            ),
          ),
          const SizedBox(height: 16),
          if (!isMandatory)
            TextButton.icon(
              onPressed: () {
                ref.read(appUpdateNotifierProvider.notifier).cancelDownload();
              },
              icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
              label: const Text('Batalkan', style: TextStyle(color: AppColors.textMuted)),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Downloaded content — ready to install
// ---------------------------------------------------------------------------

class _DownloadedContent extends ConsumerWidget {
  const _DownloadedContent({required this.info, required this.isMandatory});

  final AppVersionInfo info;
  final bool isMandatory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 42),
          ),
          const SizedBox(height: 16),
          const Text(
            'Download Selesai!',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          const Text(
            'Mempersiapkan installer...',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          const LinearProgressIndicator(color: AppColors.primary),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Installing content — spinner
// ---------------------------------------------------------------------------

class _InstallingContent extends StatelessWidget {
  const _InstallingContent();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(strokeWidth: 5, color: AppColors.primary),
          ),
          SizedBox(height: 20),
          Text(
            'Membuka Installer...',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textDark),
          ),
          SizedBox(height: 6),
          Text(
            'Ikuti petunjuk instalasi yang muncul',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error content — retry button
// ---------------------------------------------------------------------------

class _ErrorContent extends ConsumerWidget {
  const _ErrorContent({
    required this.message,
    required this.info,
    required this.isMandatory,
  });

  final String message;
  final AppVersionInfo info;
  final bool isMandatory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline_rounded, color: Colors.red.shade600, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'Update Gagal',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textDark),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () => ref
                  .read(appUpdateNotifierProvider.notifier)
                  .retry(info),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          if (!isMandatory) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(appUpdateNotifierProvider.notifier).dismiss();
              },
              child: const Text('Nanti Saja', style: TextStyle(color: AppColors.textMuted)),
            ),
          ],
        ],
      ),
    );
  }
}
