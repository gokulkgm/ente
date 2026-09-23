import 'dart:io';

import 'package:ente_logging/logging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Wraps the macOS login-items channel backed by `SMAppService` and caches the
/// status, since the settings toggle reads it synchronously.
class LaunchAtLoginService {
  static const MethodChannel _channel = MethodChannel(
    'io.ente.auth/launch_at_login',
  );

  static final _logger = Logger("LaunchAtLoginService");

  bool _isSupported = false;
  final ValueNotifier<bool> _enabled = ValueNotifier<bool>(false);

  LaunchAtLoginService._privateConstructor();

  static final LaunchAtLoginService instance =
      LaunchAtLoginService._privateConstructor();

  bool get isSupported => _isSupported;

  /// Notifies when a refresh observes a status change, e.g. the user toggling
  /// the login item in System Settings while Auth stays open.
  ValueListenable<bool> get enabledListenable => _enabled;

  bool get isEnabled => _enabled.value;

  Future<void> init() async {
    if (!Platform.isMacOS) return;
    try {
      _isSupported = await _channel.invokeMethod<bool>('isSupported') ?? false;
    } catch (e, s) {
      _logger.warning("Failed to query launch at login support", e, s);
      _isSupported = false;
    }
    await refresh();
  }

  /// Re-reads the status from the OS, which can change it while the app is
  /// running (System Settings → Login Items).
  Future<void> refresh() async {
    if (!_isSupported) return;
    try {
      _enabled.value = await _channel.invokeMethod<bool>('isEnabled') ?? false;
    } catch (e, s) {
      _logger.warning("Failed to refresh launch at login status", e, s);
    }
  }

  Future<void> setEnabled(bool enabled) async {
    await _channel.invokeMethod<void>('setEnabled', enabled);
    // Registration may leave the status at `.requiresApproval`, so cache the
    // actual OS status rather than the requested value.
    await refresh();
  }
}
