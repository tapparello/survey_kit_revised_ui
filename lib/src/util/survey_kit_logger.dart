import 'package:logger/logger.dart';

/// Log severity for [SurveyKitLogger].
///
/// Aliases `package:logger`'s `Level` so consumers need not take a direct
/// dependency on `logger`, and so the bare name `Level` never enters their
/// namespace — it collides with `package:logging`, which the FMF Connect app
/// imports in 60 files.
typedef SurveyKitLogLevel = Level;

/// Centralized logger for SurveyKit
///
/// This logger is used internally by SurveyKit for debugging and diagnostic information.
/// Apps using SurveyKit can control the logging level to show or hide internal logs.
///
/// Usage from your app:
/// ```dart
/// import 'package:survey_kit/survey_kit.dart';
///
/// // Control SurveyKit's internal logging level
/// SurveyKitLogger.setLevel(SurveyKitLogLevel.warning); // warnings and errors
/// SurveyKitLogger.setLevel(SurveyKitLogLevel.off);     // no SurveyKit logs
/// SurveyKitLogger.setLevel(SurveyKitLogLevel.debug);   // all debug info
/// ```
///
/// Available log levels (from most to least verbose):
/// - Level.trace, Level.debug, Level.info, Level.warning, Level.error, Level.fatal, Level.off
class SurveyKitLogger {
  static Logger? _logger;

  /// Get the logger instance, creating it if it doesn't exist
  static Logger get logger {
    _logger ??= Logger(
      level: _getDefaultLevel(),
      printer: PrettyPrinter(
        methodCount: 2, // Number of method calls to be displayed
        errorMethodCount: 8, // Number of method calls if stacktrace is provided
        lineLength: 120, // Width of the output
        colors: true, // Colorful log messages
        printEmojis: true, // Print an emoji for each log message
        dateTimeFormat: DateTimeFormat.onlyTime,
      ),
    );
    return _logger!;
  }

  /// Set the logging level
  ///
  /// Available levels:
  /// - Level.trace (most verbose)
  /// - Level.debug
  /// - Level.info
  /// - Level.warning
  /// - Level.error
  /// - Level.fatal (least verbose)
  /// - Level.off (no logging)
  static void setLevel(Level level) {
    _logger = Logger(
      level: level,
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTime,
      ),
    );
  }

  /// Get default log level based on build mode
  static Level _getDefaultLevel() {
    // In debug mode, show all logs. In release mode, only show info and above
    var isDebugMode = false;
    assert(
      isDebugMode = true,
      'Debug mode detection',
    ); // This only runs in debug mode
    return isDebugMode ? Level.debug : Level.info;
  }

  /// Debug level logging - for detailed diagnostic information
  static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Info level logging - for general information
  static void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Warning level logging - for potentially harmful situations
  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Error level logging - for error events
  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Verbose level logging - for very detailed diagnostic information
  static void v(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    logger.t(message, error: error, stackTrace: stackTrace);
  }
}
