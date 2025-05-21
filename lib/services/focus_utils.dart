import 'package:flutter/material.dart';
import 'dart:async';

/// A utility class for managing focus changes in a controlled way.
class FocusUtils {
  static bool _haveScheduledUpdate = false;

  /// Apply any pending focus changes.
  /// This should be called after the current frame.
  static void applyFocusChangesIfNeeded() {
    _haveScheduledUpdate = false;
    FocusManager.instance.primaryFocus?.unfocus();
  }

  /// Schedule a focus change after the current frame.
  /// Safer than using scheduleMicrotask to avoid framework errors.
  static void scheduleFocusChange() {
    if (!_haveScheduledUpdate) {
      _haveScheduledUpdate = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        applyFocusChangesIfNeeded();
      });
    }
  }

  /// Unfocus any text fields and ensure the keyboard is dismissed.
  /// Returns a Future that completes after the focus change.
  static Future<void> ensureUnfocused() async {
    FocusManager.instance.primaryFocus?.unfocus();
    scheduleFocusChange();
    await Future.delayed(const Duration(milliseconds: 300));
  }
}