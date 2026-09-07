import 'dart:async';
import 'dart:io';

/// What to tell the user when a request did not come back.
///
/// Raw transport exceptions name internal hosts and read like a stack trace
/// wearing a snackbar, so they never reach the screen verbatim.
String friendlyNetworkError(Object error) {
  if (error is SocketException) return _offline;
  if (error is TimeoutException) return _slow;

  final text = error.toString().toLowerCase();

  // http's ClientException keeps the cause in its message rather than as a
  // typed error, so the checks above miss the most common case.
  if (text.contains('failed host lookup') ||
      text.contains('socketexception') ||
      text.contains('network is unreachable') ||
      text.contains('connection refused') ||
      text.contains('connection closed')) {
    return _offline;
  }
  if (text.contains('timeout') || text.contains('timed out')) return _slow;

  return 'Could not reach Tickerless. Try again in a moment.';
}

const _offline = 'No internet connection.';
const _slow = 'The network is taking too long. Try again.';
