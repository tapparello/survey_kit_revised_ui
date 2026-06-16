import 'package:json_annotation/json_annotation.dart';

part 'scale_band.g.dart';

/// A contiguous value range on a vertical scale slider with a localizable
/// [name]. Drives both the tooltip (any value in [min]..[max]) and the static
/// tick label (shown only at the [labelAt] tick).
@JsonSerializable(explicitToJson: true)
class ScaleBand {
  /// Inclusive lower bound of the value range this band covers.
  final double min;

  /// Inclusive upper bound of the value range this band covers.
  final double max;

  /// The localizable band name (the displayed string).
  final String name;

  /// The single tick value at which this band's [name] is shown as a static
  /// label. Every other tick is blank.
  final double labelAt;

  const ScaleBand({
    required this.min,
    required this.max,
    required this.name,
    required this.labelAt,
  });

  factory ScaleBand.fromJson(Map<String, dynamic> json) => _$ScaleBandFromJson(json);
  Map<String, dynamic> toJson() => _$ScaleBandToJson(this);
}
