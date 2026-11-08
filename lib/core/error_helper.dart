import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Central place to convert low-level exceptions into user-friendly strings
/// for the admin app. Same behaviour as the karaoke app's ErrorHelper, so
/// admins see the same plain-English messages across both tools.
class ErrorHelper {
  /// Convert any caught error into a clean, human-readable message.
  ///
  /// Pass [context] like "loading users" or "deleting the song".
  static String friendly(Object error, {String context = 'completing that request'}) {
    if (error is TimeoutException) {
      return 'The server is taking too long to respond. '
          'It may be waking up — please try again in a few seconds.';
    }

    if (error is http.ClientException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('xmlhttprequest') ||
          msg.contains('failed host lookup') ||
          msg.contains('network is unreachable') ||
          msg.contains('connection refused') ||
          msg.contains('connection reset')) {
        return 'No internet connection. Please check your signal and try again.';
      }
      return 'Could not reach the server. Please try again.';
    }

    if (error is SocketException) {
      return 'No internet connection. Please check your signal and try again.';
    }

    if (error is HandshakeException) {
      return 'Secure connection failed. Please try again on a different network.';
    }

    final raw = error.toString();
    final cleaned = _stripExceptionPrefix(raw);
    final lower = cleaned.toLowerCase();

    if (lower.contains('unauthorized') || lower.contains('401')) {
      return 'Your session has expired. Please log in again.';
    }
    if (lower.contains('forbidden') || lower.contains('403')) {
      return 'You don\'t have permission to do that.';
    }
    if (lower.contains('not found') || lower.contains('404')) {
      return 'We couldn\'t find that item. It may have been removed.';
    }
    if (lower.contains('invalid credentials')) {
      return 'Wrong email or password. Please try again.';
    }
    if (lower.contains('network') || lower.contains('socket')) {
      return 'No internet connection. Please check your signal and try again.';
    }

    if (cleaned.isNotEmpty &&
        cleaned.length < 200 &&
        !cleaned.toLowerCase().startsWith('network error:')) {
      return cleaned;
    }

    return 'Couldn\'t $context. Please try again.';
  }

  static String _stripExceptionPrefix(String raw) {
    String s = raw.trim();
    while (s.startsWith('Exception:')) {
      s = s.substring('Exception:'.length).trim();
    }
    if (s.toLowerCase().startsWith('network error:')) {
      s = s.substring('network error:'.length).trim();
    }
    return s;
  }

  static bool isAuthError(Object error) {
    final s = error.toString().toLowerCase();
    return s.contains('401') || s.contains('unauthorized');
  }
}
