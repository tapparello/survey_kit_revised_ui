import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart' hide Content;
import 'package:survey_kit/src/engine/survey_feedback.dart';

/// The one place a [FeedbackTone] becomes a colour.
///
/// `neutral` maps to `null`, NOT to `Colors.transparent`: the button's text
/// colour below is chosen from `backgroundColor != null`, so a transparent
/// background would render white text on the ambient dialog surface.
Color? _backgroundFor(FeedbackTone tone) => switch (tone) {
  FeedbackTone.correct => Colors.green,
  FeedbackTone.incorrect => Colors.red,
  FeedbackTone.neutral => null,
};

/// Shows the answer feedback dialog and completes when it closes.
///
/// The returned future is `showDialog`'s own, NOT a Completer resolved from
/// the tap handler and the auto-dismiss timer. `barrierDismissible: false`
/// disables the barrier TAP only; the Android hardware back button still pops
/// the dialog route without running either. A Completer would therefore never
/// complete on a back-dismissal — hanging the engine's await forever and,
/// given the re-entrancy guard, freezing the survey permanently. `showDialog`'s
/// future completes on every dismissal path. (ADO #1040)
Future<void> showSurveyFeedbackDialog({
  required GlobalKey<NavigatorState> navigatorKey,
  required SurveyFeedback feedback,
  required Map<String, String>? localizations,
}) {
  final message = feedback.message;
  final autoDismiss = feedback.autoDismiss;
  final backgroundColor = _backgroundFor(feedback.tone);

  final htmlStyle = <String, Style>{
    'p': Style(
      textAlign: TextAlign.center,
      fontWeight: FontWeight.bold,
      fontSize: FontSize(16.0),
    ),
    'ul': Style(fontSize: FontSize(16.0)),
  };

  final dialogClosed = showDialog<void>(
    context: navigatorKey.currentContext!,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        backgroundColor: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Html(data: '<strong>$message</strong>', style: htmlStyle),
              const SizedBox(height: 15),
              if (!autoDismiss)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    localizations?['next'] ?? 'Next',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: (backgroundColor != null)
                          ? Colors.white
                          : Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
      );
    },
  );

  // Scheduled AFTER showDialog, preserving the pre-3b ordering. Scheduling it
  // before would start the timer before the route exists.
  //
  // The `closed` check is NOT belt-and-braces. On the autoDismiss branch
  // the dialog renders SizedBox.shrink() instead of a button, so the timer and
  // the hardware back button are its only two exits — and 3b promotes back
  // dismissal to a supported path. Without the check, a back press at t=0.5s
  // pops the dialog and advances the survey, and then at t=1.0s this pops
  // AGAIN, this time taking the host's own route with it.
  if (autoDismiss) {
    var closed = false;
    unawaited(dialogClosed.whenComplete(() => closed = true));
    unawaited(
      Future.delayed(const Duration(seconds: 1), () {
        if (closed) return;
        final context = navigatorKey.currentContext;
        if (context == null) return;
        Navigator.of(context, rootNavigator: true).pop();
      }),
    );
  }

  return dialogClosed;
}
