/// Models for in-app APK update feature.
library;

/// Status of the version check result.
enum UpdateStatus {
  /// App is already up to date.
  upToDate,
  /// A new version is available but update is optional.
  updateAvailable,
  /// A new version is available and update is REQUIRED before continuing.
  mandatoryUpdate,
  /// API unreachable or no version published yet — treat as up to date.
  unavailable,
}

/// Data class returned by the API at GET /api/v1/app/version
class AppVersionInfo {
  const AppVersionInfo({
    required this.versionName,
    required this.versionCode,
    required this.downloadUrl,
    required this.isMandatory,
    this.releaseNotes,
    this.platform = 'android',
  });

  final String versionName;
  final int versionCode;
  final String downloadUrl;
  final bool isMandatory;
  final String? releaseNotes;
  final String platform;

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) => AppVersionInfo(
        versionName: json['versionName'] as String? ?? '',
        versionCode: (json['versionCode'] as num?)?.toInt() ?? 0,
        downloadUrl: json['downloadUrl'] as String? ?? '',
        isMandatory: json['isMandatory'] as bool? ?? false,
        releaseNotes: json['releaseNotes'] as String?,
        platform: json['platform'] as String? ?? 'android',
      );
}

/// Combined result of a version check: what's available and what action to take.
class UpdateCheckResult {
  const UpdateCheckResult({
    required this.status,
    this.latestVersion,
  });

  final UpdateStatus status;

  /// Only populated when status != upToDate && status != unavailable.
  final AppVersionInfo? latestVersion;

  bool get hasUpdate =>
      status == UpdateStatus.updateAvailable ||
      status == UpdateStatus.mandatoryUpdate;
}
