import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/model/content/content.dart';
import 'package:survey_kit/src/model/content/styled_text_content.dart';
import 'package:survey_kit/src/view/widget/content/lottie_widget.dart';

part 'lottie_content.g.dart';

@JsonSerializable()
class LottieContent extends Content {
  static const type = 'lottie';

  final String? url;
  final String? asset;
  final bool repeat;
  final double width;
  final double height;

  const LottieContent({
    this.url,
    this.asset,
    this.repeat = false,
    this.width = 100,
    this.height = 100,
    super.id,
  }) : assert(url != null || asset != null, 'Either url or asset must be set'),
       super(contentType: type);

  factory LottieContent.fromJson(Map<String, dynamic> json) =>
      _$LottieContentFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$LottieContentToJson(this);

  @override
  Widget createWidget({
    Map<String, dynamic> variables = const {},
    Map<String, StyledTextContent>? contentStyles,
  }) {
    return LottieWidget(lottieContent: this);
  }
}
