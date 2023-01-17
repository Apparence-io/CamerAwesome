import 'dart:ui';

import 'package:colorfilter_generator/presets.dart';
import 'package:photofilters/photofilters.dart' as PhotoFilters;

class AwesomeFilter {
  final ColorFilter _previewFilter;
  final PhotoFilters.Filter _outputFilter;

  AwesomeFilter({
    required ColorFilter previewFilter,
    required PhotoFilters.Filter outputFilter,
  })  : _previewFilter = previewFilter,
        _outputFilter = outputFilter;

  ColorFilter get preview => _previewFilter;
  PhotoFilters.Filter get output => _outputFilter;

  static AwesomeFilter get none => AwesomeFilter(
        previewFilter: ColorFilter.matrix(
          PresetFilters.none.matrix,
        ),
        outputFilter: PhotoFilters.NoFilter(),
      );
  static AwesomeFilter get addictiveBlue => AwesomeFilter(
        previewFilter: ColorFilter.matrix(
          PresetFilters.addictiveBlue.matrix,
        ),
        outputFilter: PhotoFilters.AddictiveBlueFilter(),
      );
  static AwesomeFilter get addictiveRed => AwesomeFilter(
        previewFilter: ColorFilter.matrix(
          PresetFilters.addictiveRed.matrix,
        ),
        outputFilter: PhotoFilters.AddictiveRedFilter(),
      );
}
