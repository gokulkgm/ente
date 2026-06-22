import 'dart:io';

import 'package:ente_logging/logging.dart';
import 'package:flutter/services.dart';

class LaunchAtLoginService {
  LaunchAtLoginService._privateConstructor();
  static final LaunchAtLoginService instance =
      LaunchAtLoginService._privateConstructor();

  static const _channel = MethodChannel('io.ente.auth/launchAtLogin');
  final _logger = Logger("LaunchAtLoginService");

  bool _wasAutoLaunched = false;
  bool get wasAutoLaunched => _wasAutoLaunched;

  static bool get isSupported => Platform.isMacOS;

  Future<void> init() async {
    if (!isSupported) return;
    try {
      _wasAutoLaunched = await _channel.invokeMethod<bool>('wasAutoLaunched') ?? false;
    } catch (e) {
      _logger.warning("Failed to check auto-launch status", e);
    }
  }

  Future<bool> isEnabled() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('isEnabled') ?? false;
    } catch (e) {
      _logger.warning("Failed to check launch-at-login status", e);
      return false;
    }
  }

  Future<void> setEnabled(bool value) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod(value ? 'enable' : 'disable');
    } catch (e) {
      _logger.warning("Failed to ${value ? 'enable' : 'disable'} launch-at-login", e);
      rethrow;
    }
  }
}
