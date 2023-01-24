import 'dart:ui';

import 'package:colorfilter_generator/addons.dart';
import 'package:colorfilter_generator/colorfilter_generator.dart';
import 'package:colorfilter_generator/presets.dart';
import 'package:photofilters/photofilters.dart' as PhotoFilters;

// TODO: colorfilter_generator can be removed from dependencies
// find a way to do it with photofilters only
class AwesomeFilter {
  final String _name;
  final PhotoFilters.Filter _outputFilter;
  final List<double> matrix;

  AwesomeFilter({
    required String name,
    required PhotoFilters.Filter outputFilter,
    required this.matrix,
  })  : _name = name,
        _outputFilter = outputFilter;

  ColorFilter get preview => ColorFilter.matrix(matrix);

  PhotoFilters.Filter get output => _outputFilter;

  String get name => _name;

  String get id => _name.toUpperCase().replaceAll(' ', '_');

  static AwesomeFilter get None => AwesomeFilter(
        // TODO: add translation
        name: 'Original',
        outputFilter: PhotoFilters.NoFilter(),
        matrix: PresetFilters.none.matrix,
      );

  static AwesomeFilter get AddictiveBlue => AwesomeFilter(
    name: 'Addictive Blue',
        outputFilter: PhotoFilters.AddictiveBlueFilter(),
        matrix: PresetFilters.addictiveBlue.matrix,
      );

  static AwesomeFilter get AddictiveRed => AwesomeFilter(
    name: 'Addictive Red',
        outputFilter: PhotoFilters.AddictiveRedFilter(),
        matrix: PresetFilters.addictiveRed.matrix,
      );

  static AwesomeFilter get Aden => AwesomeFilter(
    name: 'Aden',
        outputFilter: PhotoFilters.AdenFilter(),
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
        outputFilter: PhotoFilters.AmaroFilter(),
        matrix: PresetFilters.amaro.matrix,
      );

  static AwesomeFilter get Ashby => AwesomeFilter(
    name: 'Ashby',
        outputFilter: PhotoFilters.AshbyFilter(),
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
        outputFilter: PhotoFilters.BrannanFilter(),
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
        outputFilter: PhotoFilters.BrooklynFilter(),
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
        outputFilter: PhotoFilters.ClarendonFilter(),
        matrix: PresetFilters.clarendon.matrix,
      );

  static AwesomeFilter get Crema => AwesomeFilter(
    name: 'Crema',
        outputFilter: PhotoFilters.CremaFilter(),
        matrix: PresetFilters.crema.matrix,
      );

  static AwesomeFilter get Dogpatch => AwesomeFilter(
    name: 'Dogpatch',
        outputFilter: PhotoFilters.DogpatchFilter(),
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
        outputFilter: PhotoFilters.GinghamFilter(),
        matrix: PresetFilters.gingham.matrix,
      );

  static AwesomeFilter get Ginza => AwesomeFilter(
    name: 'Ginza',
        outputFilter: PhotoFilters.GinzaFilter(),
        matrix: PresetFilters.ginza.matrix,
      );

  static AwesomeFilter get Hefe => AwesomeFilter(
    name: 'Hefe',
        outputFilter: PhotoFilters.HefeFilter(),
        matrix: PresetFilters.hefe.matrix,
      );

  // static AwesomeFilter get Helena => AwesomeFilter(
  //   name: 'Helena',
  //       outputFilter: PhotoFilters.HelenaFilter(),
  //       matrix: PresetFilters.helena.matrix,
  //     );

  static AwesomeFilter get Hudson => AwesomeFilter(
    name: 'Hudson',
        outputFilter: PhotoFilters.HudsonFilter(),
        matrix: PresetFilters.hudson.matrix,
      );

  static AwesomeFilter get Inkwell => AwesomeFilter(
    name: 'Inkwell',
        outputFilter: PhotoFilters.InkwellFilter(),
        matrix: PresetFilters.inkwell.matrix,
      );

  static AwesomeFilter get Juno => AwesomeFilter(
    name: 'Juno',
        outputFilter: PhotoFilters.JunoFilter(),
        matrix: PresetFilters.juno.matrix,
      );

  // static AwesomeFilter get Kelvin => AwesomeFilter(
  //   name: 'Kelvin',
  //       outputFilter: PhotoFilters.KelvinFilter(),
  //       matrix: PresetFilters.kelvin.matrix,
  //     );

  static AwesomeFilter get Lark => AwesomeFilter(
    name: 'Lark',
        outputFilter: PhotoFilters.LarkFilter(),
        matrix: PresetFilters.lark.matrix,
      );

  static AwesomeFilter get LoFi => AwesomeFilter(
    name: 'Lo-Fi',
        outputFilter: PhotoFilters.LoFiFilter(),
        matrix: PresetFilters.loFi.matrix,
      );

  static AwesomeFilter get Ludwig => AwesomeFilter(
    name: 'Ludwig',
        outputFilter: PhotoFilters.LudwigFilter(),
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
        outputFilter: PhotoFilters.MoonFilter(),
        matrix: PresetFilters.moon.matrix,
      );

  // static AwesomeFilter get Nashville => AwesomeFilter(
  //   name: 'Nashville',
  //       outputFilter: PhotoFilters.NashvilleFilter(),
  //       matrix: PresetFilters.nashville.matrix,
  //     );

  static AwesomeFilter get Perpetua => AwesomeFilter(
    name: 'Perpetua',
        outputFilter: PhotoFilters.PerpetuaFilter(),
        matrix: PresetFilters.perpetua.matrix,
      );

  static AwesomeFilter get Reyes => AwesomeFilter(
    name: 'Reyes',
        outputFilter: PhotoFilters.ReyesFilter(),
        matrix: PresetFilters.reyes.matrix,
      );

  // static AwesomeFilter get Rise => AwesomeFilter(
  //   name: 'Rise',
  //       outputFilter: PhotoFilters.RiseFilter(),
  //       matrix: PresetFilters.rise.matrix,
  //     );

  static AwesomeFilter get Sierra => AwesomeFilter(
    name: 'Sierra',
        outputFilter: PhotoFilters.SierraFilter(),
        matrix: PresetFilters.sierra.matrix,
      );

  // static AwesomeFilter get Skyline => AwesomeFilter(
  //   name: 'Skyline',
  //       outputFilter: PhotoFilters.SkylineFilter(),
  //       matrix: PresetFilters.skyline.matrix,
  //     );

  static AwesomeFilter get Slumber => AwesomeFilter(
    name: 'Slumber',
        outputFilter: PhotoFilters.SlumberFilter(),
        matrix: PresetFilters.slumber.matrix,
      );

  static AwesomeFilter get Stinson => AwesomeFilter(
    name: 'Stinson',
        outputFilter: PhotoFilters.StinsonFilter(),
        matrix: PresetFilters.stinson.matrix,
      );

  static AwesomeFilter get Sutro => AwesomeFilter(
    name: 'Sutro',
        outputFilter: PhotoFilters.SutroFilter(),
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
      outputFilter: PhotoFilters.WaldenFilter(),
      matrix: ColorFilterGenerator(
        name: "Walden",
        filters: [
          ColorFilterAddons.brightness(0.1),
          ColorFilterAddons.addictiveColor(45, 45, 0),
        ],
      ).matrix);

  static AwesomeFilter get Willow => AwesomeFilter(
        name: 'Willow',
        outputFilter: PhotoFilters.WillowFilter(),
        matrix: PresetFilters.willow.matrix,
      );

  static AwesomeFilter get XProII => AwesomeFilter(
        name: 'X-Pro II',
        outputFilter: PhotoFilters.XProIIFilter(),
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
