import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:survey_kit/survey_kit.dart';

class LottieWidget extends StatelessWidget {
  const LottieWidget({
    super.key,
    required this.lottieContent,
  });

  final LottieContent lottieContent;

  @override
  Widget build(BuildContext context) {
    if (lottieContent.url == null && lottieContent.asset == null) {
      return const Text('Either url or asset must be set');
    }

    if (lottieContent.url != null) {
      return Lottie.network(
        lottieContent.url!,
        repeat: lottieContent.repeat,
      );
    }

    return Lottie.asset(
      lottieContent.asset!,
      repeat: lottieContent.repeat,
    );
  }
}
