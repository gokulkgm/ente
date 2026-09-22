import 'dart:io';

import 'package:ente_logging/logging.dart';
import 'package:flutter/services.dart';

/// Wraps the macOS login-items channel backed by `SMAppService` and caches the
/// status, since the settings toggle reads it synchronously.
class LaunchAtLoginService {
  static const MethodChannel _channel = MethodChannel(
    'io.ente.auth/launch_at_login',
  );

  static final _logger = Logger("LaunchAtLoginService");

  bool _isSupported = false;
  bool _isEnabled = false;

  LaunchAtLoginService._privateConstructor();

  static final LaunchAtLoginService instance =
      LaunchAtLoginService._privateConstructor();

  bool get isSupported => _isSupported;

  bool get isEnabled => _isEnabled;

  Future<void> init() async {
    if (!Platform.isMacOS) return;
    try {
      _isSupported = await _channel.invokeMethod<bool>('isSupported') ?? false;
      _isEnabled =
          _isSupported &&
          (await _channel.invokeMethod<bool>('isEnabled') ?? false);
    } catch (e, s) {
      _logger.warning("Failed to query launch at login status", e, s);
      _isSupported = false;
      _isEnabled = false;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    await _channel.invokeMethod<void>('setEnabled', enabled);
    _isEnabled = enabled;
  }
}
