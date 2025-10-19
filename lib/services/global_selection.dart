import 'package:flutter/services.dart';

class SelectionData {
  final String text;
  final double cursorX;
  final double cursorY;

  SelectionData({required this.text, required this.cursorX, required this.cursorY});

  factory SelectionData.fromMap(Map<dynamic, dynamic> map) {
    return SelectionData(
      text: map['text'] ?? '',
      cursorX: (map['cursorX'] as num?)?.toDouble() ?? 0.0,
      cursorY: (map['cursorY'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

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
  static Future<dynamic?> getSelectedText() async {
    try {
      final dynamic data = await _channel.invokeMethod<dynamic>('getSelectedText');
      return data;
    } catch (_) {
      return null;
    }
  }

  /// Returns both selected text and cursor position from the focused element in any app (macOS only).
  /// Returns null if no selection, element not readable, or permission is not granted.
  static Future<SelectionData?> getSelectedTextWithCursor() async {
    try {
      final Map<dynamic, dynamic>? data = await _channel.invokeMethod<Map<dynamic, dynamic>>('getSelectedText');
      if (data == null) return null;
      return SelectionData.fromMap(data);
    } catch (_) {
      return null;
    }
  }
}