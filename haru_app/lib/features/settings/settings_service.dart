import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _storage = FlutterSecureStorage();
  static const _kReminderEnabled = 'settings_reminder_enabled';
  static const _kReminderHour = 'settings_reminder_hour';
  static const _kReminderMinute = 'settings_reminder_minute';

  Future<({bool enabled, TimeOfDay reminderTime})> load() async {
    final enabledRaw = await _storage.read(key: _kReminderEnabled);
    final hourRaw = await _storage.read(key: _kReminderHour);
    final minuteRaw = await _storage.read(key: _kReminderMinute);

    final enabled = enabledRaw == null ? true : enabledRaw == 'true';
    final hour = int.tryParse(hourRaw ?? '') ?? 21;
    final minute = int.tryParse(minuteRaw ?? '') ?? 0;

    return (
      enabled: enabled,
      reminderTime: TimeOfDay(hour: hour, minute: minute),
    );
  }

  Future<void> setReminderEnabled(bool enabled) async {
    await _storage.write(key: _kReminderEnabled, value: enabled.toString());
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    await _storage.write(key: _kReminderHour, value: time.hour.toString());
    await _storage.write(key: _kReminderMinute, value: time.minute.toString());
  }
}
