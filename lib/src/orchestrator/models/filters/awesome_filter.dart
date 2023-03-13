// ignore_for_file: non_constant_identifier_names

import 'dart:ui';

import 'package:colorfilter_generator/addons.dart';
import 'package:colorfilter_generator/colorfilter_generator.dart';
import 'package:colorfilter_generator/presets.dart';
import 'package:camerawesome/src/photofilters/filters/filters.dart'
    as photofilters;
import 'package:camerawesome/src/photofilters/filters/preset_filters.dart'
    as preset_filters;

// TODO: colorfilter_generator can be removed from dependencies
// find a way to do it with photofilters only
class AwesomeFilter {
  final String _name;
  final photofilters.Filter _outputFilter;
  final List<double> matrix;

  AwesomeFilter({
    required String name,
    required photofilters.Filter outputFilter,
    required this.matrix,
  })  : _name = name,
        _outputFilter = outputFilter;

  ColorFilter get preview => ColorFilter.matrix(matrix);

  photofilters.Filter get output => _outputFilter;

  String get name => _name;

  String get id => _name.toUpperCase().replaceAll(' ', '_');

  static AwesomeFilter get None => AwesomeFilter(
        // TODO: add translation
        name: 'Original',
        outputFilter: preset_filters.NoFilter(),
        matrix: PresetFilters.none.matrix,
      );

  static AwesomeFilter get AddictiveBlue => AwesomeFilter(
        name: 'Addictive Blue',
        outputFilter: preset_filters.AddictiveBlueFilter(),
        matrix: PresetFilters.addictiveBlue.matrix,
      );

  static AwesomeFilter get AddictiveRed => AwesomeFilter(
        name: 'Addictive Red',
        outputFilter: preset_filters.AddictiveRedFilter(),
        matrix: PresetFilters.addictiveRed.matrix,
      );

  static AwesomeFilter get Aden => AwesomeFilter(
        name: 'Aden',
        outputFilter: preset_filters.AdenFilter(),
        matrix: ColorFilterGenerator(
          name: 'Aden',
          filters: [
            ColorFilterAddons.addictiveColor(48, 30, 45),
            ColorFilterAddons.saturation(-0.2),
          ],
        ).matrix,
      );

  static AwesomeFilter get Amaro => AwesomeFilter(
        name: 'Amaro',
        outputFilter: preset_filters.AmaroFilter(),
        matrix: PresetFilters.amaro.matrix,
      );

  static AwesomeFilter get Ashby => AwesomeFilter(
        name: 'Ashby',
        outputFilter: preset_filters.AshbyFilter(),
        matrix: ColorFilterGenerator(
          name: 'Ashby',
          filters: [
            ColorFilterAddons.addictiveColor(45, 30, 15),
            ColorFilterAddons.brightness(0.1),
          ],
        ).matrix,
      );

  static AwesomeFilter get Brannan => AwesomeFilter(
        name: 'Brannan',
        outputFilter: preset_filters.BrannanFilter(),
        matrix: ColorFilterGenerator(
          name: 'Brannan',
          filters: [
            ColorFilterAddons.contrast(0.23),
            ColorFilterAddons.addictiveColor(7, 7, 25),
          ],
        ).matrix,
      );

  static AwesomeFilter get Brooklyn => AwesomeFilter(
        name: 'Brooklyn',
        outputFilter: preset_filters.BrooklynFilter(),
        matrix: ColorFilterGenerator(
          name: 'Brooklyn',
          filters: [
            ColorFilterAddons.sepia(0.4),
            ColorFilterAddons.brightness(-0.1),
            ColorFilterAddons.addictiveColor(25, 30, 42),
          ],
        ).matrix,
      );

  // static AwesomeFilter get Charmes => AwesomeFilter(
  //   name: 'Charmes',
  //       outputFilter: PhotoFilters.CharmesFilter(),
  //       matrix: PresetFilters.charmes.matrix,
  //     );

  static AwesomeFilter get Clarendon => AwesomeFilter(
        name: 'Clarendon',
        outputFilter: preset_filters.ClarendonFilter(),
        matrix: PresetFilters.clarendon.matrix,
      );

  static AwesomeFilter get Crema => AwesomeFilter(
        name: 'Crema',
        outputFilter: preset_filters.CremaFilter(),
        matrix: PresetFilters.crema.matrix,
      );

  static AwesomeFilter get Dogpatch => AwesomeFilter(
        name: 'Dogpatch',
        outputFilter: preset_filters.DogpatchFilter(),
        matrix: PresetFilters.dogpatch.matrix,
      );

  // static AwesomeFilter get Earlybird => AwesomeFilter(
  //   name: 'Earlybird',
  //       outputFilter: PhotoFilters.EarlybirdFilter(),
  //       matrix: PresetFilters.earlybird.matrix,
  //     );

  // static AwesomeFilter get f1977 => AwesomeFilter(
  //   name: '1977',
  //       outputFilter: PhotoFilters.F1977Filter(),
  //       matrix: PresetFilters.f1977.matrix,
  //     );

  static AwesomeFilter get Gingham => AwesomeFilter(
        name: 'Gingham',
        outputFilter: preset_filters.GinghamFilter(),
        matrix: PresetFilters.gingham.matrix,
      );

  static AwesomeFilter get Ginza => AwesomeFilter(
        name: 'Ginza',
        outputFilter: preset_filters.GinzaFilter(),
        matrix: PresetFilters.ginza.matrix,
      );

  static AwesomeFilter get Hefe => AwesomeFilter(
        name: 'Hefe',
        outputFilter: preset_filters.HefeFilter(),
        matrix: PresetFilters.hefe.matrix,
      );

  // static AwesomeFilter get Helena => AwesomeFilter(
  //   name: 'Helena',
  //       outputFilter: PhotoFilters.HelenaFilter(),
  //       matrix: PresetFilters.helena.matrix,
  //     );

  static AwesomeFilter get Hudson => AwesomeFilter(
        name: 'Hudson',
        outputFilter: preset_filters.HudsonFilter(),
        matrix: PresetFilters.hudson.matrix,
      );

  static AwesomeFilter get Inkwell => AwesomeFilter(
        name: 'Inkwell',
        outputFilter: preset_filters.InkwellFilter(),
        matrix: PresetFilters.inkwell.matrix,
      );

  static AwesomeFilter get Juno => AwesomeFilter(
        name: 'Juno',
        outputFilter: preset_filters.JunoFilter(),
        matrix: PresetFilters.juno.matrix,
      );

  // static AwesomeFilter get Kelvin => AwesomeFilter(
  //   name: 'Kelvin',
  //       outputFilter: PhotoFilters.KelvinFilter(),
  //       matrix: PresetFilters.kelvin.matrix,
  //     );

  static AwesomeFilter get Lark => AwesomeFilter(
        name: 'Lark',
        outputFilter: preset_filters.LarkFilter(),
        matrix: PresetFilters.lark.matrix,
      );

  static AwesomeFilter get LoFi => AwesomeFilter(
        name: 'Lo-Fi',
        outputFilter: preset_filters.LoFiFilter(),
        matrix: PresetFilters.loFi.matrix,
      );

  static AwesomeFilter get Ludwig => AwesomeFilter(
        name: 'Ludwig',
        outputFilter: preset_filters.LudwigFilter(),
        matrix: PresetFilters.ludwig.matrix,
      );

  // static AwesomeFilter get Maven => AwesomeFilter(
  //   name: 'Maven',
  //       outputFilter: PhotoFilters.MavenFilter(),
  //       matrix: PresetFilters.maven.matrix,
  //     );

  // static AwesomeFilter get Mayfair => AwesomeFilter(
  //   name: 'Mayfair',
  //       outputFilter: PhotoFilters.MayfairFilter(),
  //       matrix: PresetFilters.mayfair.matrix,
  //     );

  static AwesomeFilter get Moon => AwesomeFilter(
        name: 'Moon',
        outputFilter: preset_filters.MoonFilter(),
        matrix: PresetFilters.moon.matrix,
      );

  // static AwesomeFilter get Nashville => AwesomeFilter(
  //   name: 'Nashville',
  //       outputFilter: PhotoFilters.NashvilleFilter(),
  //       matrix: PresetFilters.nashville.matrix,
  //     );

  static AwesomeFilter get Perpetua => AwesomeFilter(
        name: 'Perpetua',
        outputFilter: preset_filters.PerpetuaFilter(),
        matrix: PresetFilters.perpetua.matrix,
      );

  static AwesomeFilter get Reyes => AwesomeFilter(
        name: 'Reyes',
        outputFilter: preset_filters.ReyesFilter(),
        matrix: PresetFilters.reyes.matrix,
      );

  // static AwesomeFilter get Rise => AwesomeFilter(
  //   name: 'Rise',
  //       outputFilter: PhotoFilters.RiseFilter(),
  //       matrix: PresetFilters.rise.matrix,
  //     );

  static AwesomeFilter get Sierra => AwesomeFilter(
        name: 'Sierra',
        outputFilter: preset_filters.SierraFilter(),
        matrix: PresetFilters.sierra.matrix,
      );

  // static AwesomeFilter get Skyline => AwesomeFilter(
  //   name: 'Skyline',
  //       outputFilter: PhotoFilters.SkylineFilter(),
  //       matrix: PresetFilters.skyline.matrix,
  //     );

  static AwesomeFilter get Slumber => AwesomeFilter(
        name: 'Slumber',
        outputFilter: preset_filters.SlumberFilter(),
        matrix: PresetFilters.slumber.matrix,
      );

  static AwesomeFilter get Stinson => AwesomeFilter(
        name: 'Stinson',
        outputFilter: preset_filters.StinsonFilter(),
        matrix: PresetFilters.stinson.matrix,
      );

  static AwesomeFilter get Sutro => AwesomeFilter(
        name: 'Sutro',
        outputFilter: preset_filters.SutroFilter(),
        matrix: PresetFilters.sutro.matrix,
      );

  // static AwesomeFilter get Toaster => AwesomeFilter(
  //   name: 'Toaster',
  //       outputFilter: PhotoFilters.ToasterFilter(),
  //       matrix: PresetFilters.toaster.matrix,
  //     );

  // static AwesomeFilter get Valencia => AwesomeFilter(
  //   name: 'Valencia',
  //       outputFilter: PhotoFilters.ValenciaFilter(),
  //       matrix: PresetFilters.valencia.matrix,
  //     );

  // static AwesomeFilter get Vesper => AwesomeFilter(
  //       name: 'Vesper',
  //       outputFilter: PhotoFilters.VesperFilter(),
  //       matrix: PresetFilters.vesper.matrix,
  //     );

  static AwesomeFilter get Walden => AwesomeFilter(
      name: 'Walden',
      outputFilter: preset_filters.WaldenFilter(),
      matrix: ColorFilterGenerator(
        name: "Walden",
        filters: [
          ColorFilterAddons.brightness(0.1),
          ColorFilterAddons.addictiveColor(45, 45, 0),
        ],
      ).matrix);

  static AwesomeFilter get Willow => AwesomeFilter(
        name: 'Willow',
        outputFilter: preset_filters.WillowFilter(),
        matrix: PresetFilters.willow.matrix,
      );

  static AwesomeFilter get XProII => AwesomeFilter(
        name: 'X-Pro II',
        outputFilter: preset_filters.XProIIFilter(),
        matrix: ColorFilterGenerator(
          name: "X-Pro II",
          filters: [
            ColorFilterAddons.addictiveColor(30, 30, 0),
            ColorFilterAddons.saturation(0.2),
            ColorFilterAddons.contrast(0.2),
            ColorFilterAddons.hue(0.03),
            ColorFilterAddons.brightness(0.04),
          ],
        ).matrix,
      );
}
