enum AutoLockTimeout {
  immediate,
  oneMinute,
}

enum SecurityOperation {
  none,
  exportingBackup,
  restoringBackup,
  wipingData,
}

class SecuritySettingsState {
  final bool isBiometricLockEnabled;
  final bool hasPinCode;
  final String maskedPin;
  final AutoLockTimeout autoLockTimeout;
  final bool isHardwareEnclaveActive;
  final bool isSqlCipherEncrypted;
  final String guestUuid;
  final bool isPrivacyScreenInMultitaskEnabled;
  final String lastBackupTime;
  final String lastBackupSize;
  final SecurityOperation currentOperation;
  final String? feedbackMessage;
  final bool isSyncingCloud;
  final DateTime? lastCloudSyncTime;
  final bool isAutoCloudSyncEnabled;

  const SecuritySettingsState({
    this.isBiometricLockEnabled = false,
    this.hasPinCode = false,
    this.maskedPin = '••••••',
    this.autoLockTimeout = AutoLockTimeout.immediate,
    this.isHardwareEnclaveActive = true,
    this.isSqlCipherEncrypted = true,
    this.guestUuid = 'f81d4fae-7dec-11d0-a765',
    this.isPrivacyScreenInMultitaskEnabled = true,
    this.lastBackupTime = '14:20 Hôm nay',
    this.lastBackupSize = '7.2 MB',
    this.currentOperation = SecurityOperation.none,
    this.feedbackMessage,
    this.isSyncingCloud = false,
    this.lastCloudSyncTime,
    this.isAutoCloudSyncEnabled = true,
  });

  String get cloudSyncTimeLabel {
    if (lastCloudSyncTime == null) return 'Chưa đồng bộ';
    final now = DateTime.now();
    final diff = now.difference(lastCloudSyncTime!);
    if (diff.inMinutes < 2) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    final hh = lastCloudSyncTime!.hour.toString().padLeft(2, '0');
    final mm = lastCloudSyncTime!.minute.toString().padLeft(2, '0');
    return '$hh:$mm Hôm nay';
  }

  SecuritySettingsState copyWith({
    bool? isBiometricLockEnabled,
    bool? hasPinCode,
    String? maskedPin,
    AutoLockTimeout? autoLockTimeout,
    bool? isHardwareEnclaveActive,
    bool? isSqlCipherEncrypted,
    String? guestUuid,
    bool? isPrivacyScreenInMultitaskEnabled,
    String? lastBackupTime,
    String? lastBackupSize,
    SecurityOperation? currentOperation,
    String? feedbackMessage,
    bool clearFeedbackMessage = false,
    bool? isSyncingCloud,
    DateTime? lastCloudSyncTime,
    bool? isAutoCloudSyncEnabled,
  }) {
    return SecuritySettingsState(
      isBiometricLockEnabled: isBiometricLockEnabled ?? this.isBiometricLockEnabled,
      hasPinCode: hasPinCode ?? this.hasPinCode,
      maskedPin: maskedPin ?? this.maskedPin,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      isHardwareEnclaveActive: isHardwareEnclaveActive ?? this.isHardwareEnclaveActive,
      isSqlCipherEncrypted: isSqlCipherEncrypted ?? this.isSqlCipherEncrypted,
      guestUuid: guestUuid ?? this.guestUuid,
      isPrivacyScreenInMultitaskEnabled:
          isPrivacyScreenInMultitaskEnabled ?? this.isPrivacyScreenInMultitaskEnabled,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
      lastBackupSize: lastBackupSize ?? this.lastBackupSize,
      currentOperation: currentOperation ?? this.currentOperation,
      feedbackMessage: clearFeedbackMessage ? null : (feedbackMessage ?? this.feedbackMessage),
      isSyncingCloud: isSyncingCloud ?? this.isSyncingCloud,
      lastCloudSyncTime: lastCloudSyncTime ?? this.lastCloudSyncTime,
      isAutoCloudSyncEnabled: isAutoCloudSyncEnabled ?? this.isAutoCloudSyncEnabled,
    );
  }
}
