import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  /// Shared text across the app using share_plus.
  static Future<void> shareText(
    BuildContext context, {
    required String text,
    String? subject,
  }) async {
    final value = text.trim();
    if (value.isEmpty) {
      debugPrint('ShareService: Attempted to share empty text');
      return;
    }

    debugPrint('ShareService: Sharing text (length: ${value.length})');

    // Detect origin for iPad/Tablets
    final renderObject = context.findRenderObject();
    final shareOrigin = renderObject is RenderBox
        ? renderObject.localToGlobal(Offset.zero) & renderObject.size
        : null;

    try {
      await Share.share(
        value,
        subject: subject,
        sharePositionOrigin: shareOrigin,
      );
    } catch (e) {
      debugPrint('ShareService: share_plus failed: $e');
      // Final fallback: Copy to clipboard
      await Clipboard.setData(ClipboardData(text: value));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Share failed. Text copied to clipboard.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Shares the app link
  static Future<void> shareApp(BuildContext context) async {
    const appText = 'Download Hisnul Muslim app for daily duas and adhkar:\n'
        'https://play.google.com/store/apps/details?id=com.deen.adkhar';
    await shareText(context, text: appText, subject: 'Hisnul Muslim App');
  }

  /// Shares files (like images)
  static Future<void> shareFiles(
    BuildContext context, {
    required List<String> paths,
    String? text,
    String? subject,
  }) async {
    if (paths.isEmpty) return;

    final renderObject = context.findRenderObject();
    final shareOrigin = renderObject is RenderBox
        ? renderObject.localToGlobal(Offset.zero) & renderObject.size
        : null;

    try {
      await Share.shareXFiles(
        paths.map((p) => XFile(p)).toList(),
        text: text,
        subject: subject,
        sharePositionOrigin: shareOrigin,
      );
    } catch (e) {
      debugPrint('share_plus files failed: $e');
    }
  }
}
