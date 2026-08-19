import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/model/content/content.dart';
import 'package:survey_kit/src/model/content/styled_text_content.dart';

part 'section_content.g.dart';

@JsonSerializable()
class SectionContent extends Content {
  static const type = 'section';

  final StyledTextContent title;
  final StyledTextContent subtitle;
  final StyledTextContent text;

  const SectionContent({
    required this.title,
    required this.subtitle,
    required this.text,
  }) : super(contentType: type);

  factory SectionContent.fromJson(Map<String, dynamic> json) =>
      _$SectionContentFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SectionContentToJson(this);
}

extension SectionContentExt on SectionContent {
  List<StyledTextContent> get toList {
    return [title, subtitle, text];
  }
}
