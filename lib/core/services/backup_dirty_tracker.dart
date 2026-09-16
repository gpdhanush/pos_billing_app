import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/database/repositories/settings_repository.dart';

/// Marks local data dirty so auto-backup knows a new upload is needed.
class BackupDirtyTracker {
  BackupDirtyTracker(this._settings);

  final SettingsRepository _settings;

  Future<void> markDirty() =>
      _settings.setBool(SettingKeys.dataChangedSinceBackup, true);

  Future<void> clearDirty() =>
      _settings.setBool(SettingKeys.dataChangedSinceBackup, false);

  Future<bool> isDirty() =>
      _settings.getBool(SettingKeys.dataChangedSinceBackup, fallback: true);
}
