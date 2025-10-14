import 'package:flutter/services.dart';

class GlobalSelectionService {
  static const MethodChannel _channel = MethodChannel('global_text_selection');

  /// Requests Accessibility permission prompt if not already granted (macOS only).
  static Future<bool> ensureAccessibilityPermission() async {
    try {
      final bool granted = await _channel.invokeMethod<bool>('ensureAccessibilityPermission') ?? false;
      return granted;
    } catch (_) {
      return false;
    }
  }

  /// Returns the currently selected text from the focused element in any app (macOS only).
  /// May return null if no selection, element not readable, or permission is not granted.
  static Future<String?> getSelectedText() async {
    try {
      final String? text = await _channel.invokeMethod<String>('getSelectedText');
      return text;
    } catch (_) {
      return null;
    }
  }
}