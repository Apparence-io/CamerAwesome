import 'dart:ui';

import 'package:colorfilter_generator/addons.dart';
import 'package:colorfilter_generator/colorfilter_generator.dart';
import 'package:colorfilter_generator/presets.dart';
import 'package:photofilters/photofilters.dart' as PhotoFilters;

// TODO: colorfilter_generator can be removed from dependencies
// find a way to do it with photofilters only
class AwesomeFilter {
  final String _name;
  final ColorFilter _previewFilter;
  final PhotoFilters.Filter _outputFilter;

  AwesomeFilter({
    required String name,
    required ColorFilter previewFilter,
    required PhotoFilters.Filter outputFilter,
  })  : _name = name,
        _previewFilter = previewFilter,
        _outputFilter = outputFilter;

  ColorFilter get preview => _previewFilter;
  PhotoFilters.Filter get output => _outputFilter;
  String get name => _name;
  String get id => _name.toUpperCase().replaceAll(' ', '_');

  static AwesomeFilter get None => AwesomeFilter(
        // TODO: add translation
        name: 'Original',
        previewFilter: ColorFilter.matrix(
          PresetFilters.none.matrix,
        ),
        outputFilter: PhotoFilters.NoFilter(),
      );
  static AwesomeFilter get AddictiveBlue => AwesomeFilter(
        name: 'Addictive Blue',
        previewFilter: ColorFilter.matrix(
          PresetFilters.addictiveBlue.matrix,
        ),
        outputFilter: PhotoFilters.AddictiveBlueFilter(),
      );
  static AwesomeFilter get AddictiveRed => AwesomeFilter(
        name: 'Addictive Red',
        previewFilter: ColorFilter.matrix(
          PresetFilters.addictiveRed.matrix,
        ),
        outputFilter: PhotoFilters.AddictiveRedFilter(),
      );
  static AwesomeFilter get Aden => AwesomeFilter(
        name: 'Aden',
        previewFilter: ColorFilter.matrix(
          ColorFilterGenerator(
            name: "Aden",
            filters: [
              ColorFilterAddons.addictiveColor(48, 30, 45),
              ColorFilterAddons.saturation(-0.2),
            ],
          ).matrix,
        ),
        outputFilter: PhotoFilters.AdenFilter(),
      );
  static AwesomeFilter get Amaro => AwesomeFilter(
        name: 'Amaro',
        previewFilter: ColorFilter.matrix(
          PresetFilters.amaro.matrix,
        ),
        outputFilter: PhotoFilters.AmaroFilter(),
      );
  static AwesomeFilter get Ashby => AwesomeFilter(
        name: 'Ashby',
        previewFilter: ColorFilter.matrix(
          PresetFilters.ashby.matrix,
        ),
        outputFilter: PhotoFilters.AshbyFilter(),
      );
  static AwesomeFilter get Brannan => AwesomeFilter(
        name: 'Brannan',
        previewFilter: ColorFilter.matrix(
          PresetFilters.brannan.matrix,
        ),
        outputFilter: PhotoFilters.BrannanFilter(),
      );
  static AwesomeFilter get Brooklyn => AwesomeFilter(
        name: 'Brooklyn',
        previewFilter: ColorFilter.matrix(
          PresetFilters.brooklyn.matrix,
        ),
        outputFilter: PhotoFilters.BrooklynFilter(),
      );
  static AwesomeFilter get Charmes => AwesomeFilter(
        name: 'Charmes',
        previewFilter: ColorFilter.matrix(
          PresetFilters.charmes.matrix,
        ),
        outputFilter: PhotoFilters.CharmesFilter(),
      );
  static AwesomeFilter get Clarendon => AwesomeFilter(
        name: 'Clarendon',
        previewFilter: ColorFilter.matrix(
          PresetFilters.clarendon.matrix,
        ),
        outputFilter: PhotoFilters.ClarendonFilter(),
      );
  static AwesomeFilter get Crema => AwesomeFilter(
        name: 'Crema',
        previewFilter: ColorFilter.matrix(
          PresetFilters.crema.matrix,
        ),
        outputFilter: PhotoFilters.CremaFilter(),
      );
  static AwesomeFilter get Dogpatch => AwesomeFilter(
        name: 'Dogpatch',
        previewFilter: ColorFilter.matrix(
          PresetFilters.dogpatch.matrix,
        ),
        outputFilter: PhotoFilters.DogpatchFilter(),
      );
  static AwesomeFilter get Earlybird => AwesomeFilter(
        name: 'Earlybird',
        previewFilter: ColorFilter.matrix(
          PresetFilters.earlybird.matrix,
        ),
        outputFilter: PhotoFilters.EarlybirdFilter(),
      );
  static AwesomeFilter get f1977 => AwesomeFilter(
        name: '1977',
        previewFilter: ColorFilter.matrix(
          PresetFilters.f1977.matrix,
        ),
        outputFilter: PhotoFilters.F1977Filter(),
      );
  static AwesomeFilter get Gingham => AwesomeFilter(
        name: 'Gingham',
        previewFilter: ColorFilter.matrix(
          PresetFilters.gingham.matrix,
        ),
        outputFilter: PhotoFilters.GinghamFilter(),
      );
  static AwesomeFilter get Ginza => AwesomeFilter(
        name: 'Ginza',
        previewFilter: ColorFilter.matrix(
          PresetFilters.ginza.matrix,
        ),
        outputFilter: PhotoFilters.GinzaFilter(),
      );
  static AwesomeFilter get Hefe => AwesomeFilter(
        name: 'Hefe',
        previewFilter: ColorFilter.matrix(
          PresetFilters.hefe.matrix,
        ),
        outputFilter: PhotoFilters.HefeFilter(),
      );
  static AwesomeFilter get Helena => AwesomeFilter(
        name: 'Helena',
        previewFilter: ColorFilter.matrix(
          PresetFilters.helena.matrix,
        ),
        outputFilter: PhotoFilters.HelenaFilter(),
      );
  static AwesomeFilter get Hudson => AwesomeFilter(
        name: 'Hudson',
        previewFilter: ColorFilter.matrix(
          PresetFilters.hudson.matrix,
        ),
        outputFilter: PhotoFilters.HudsonFilter(),
      );
  static AwesomeFilter get Inkwell => AwesomeFilter(
        name: 'Inkwell',
        previewFilter: ColorFilter.matrix(
          PresetFilters.inkwell.matrix,
        ),
        outputFilter: PhotoFilters.InkwellFilter(),
      );
  static AwesomeFilter get Juno => AwesomeFilter(
        name: 'Juno',
        previewFilter: ColorFilter.matrix(
          PresetFilters.juno.matrix,
        ),
        outputFilter: PhotoFilters.JunoFilter(),
      );
  static AwesomeFilter get Kelvin => AwesomeFilter(
        name: 'Kelvin',
        previewFilter: ColorFilter.matrix(
          PresetFilters.kelvin.matrix,
        ),
        outputFilter: PhotoFilters.KelvinFilter(),
      );
  static AwesomeFilter get Lark => AwesomeFilter(
        name: 'Lark',
        previewFilter: ColorFilter.matrix(
          PresetFilters.lark.matrix,
        ),
        outputFilter: PhotoFilters.LarkFilter(),
      );
  static AwesomeFilter get LoFi => AwesomeFilter(
        name: 'Lo-Fi',
        previewFilter: ColorFilter.matrix(
          PresetFilters.loFi.matrix,
        ),
        outputFilter: PhotoFilters.LoFiFilter(),
      );
  static AwesomeFilter get Ludwig => AwesomeFilter(
        name: 'Ludwig',
        previewFilter: ColorFilter.matrix(
          PresetFilters.ludwig.matrix,
        ),
        outputFilter: PhotoFilters.LudwigFilter(),
      );
  static AwesomeFilter get Maven => AwesomeFilter(
        name: 'Maven',
        previewFilter: ColorFilter.matrix(
          PresetFilters.maven.matrix,
        ),
        outputFilter: PhotoFilters.MavenFilter(),
      );
  static AwesomeFilter get Mayfair => AwesomeFilter(
        name: 'Mayfair',
        previewFilter: ColorFilter.matrix(
          PresetFilters.mayfair.matrix,
        ),
        outputFilter: PhotoFilters.MayfairFilter(),
      );
  static AwesomeFilter get Moon => AwesomeFilter(
        name: 'Moon',
        previewFilter: ColorFilter.matrix(
          PresetFilters.moon.matrix,
        ),
        outputFilter: PhotoFilters.MoonFilter(),
      );
  static AwesomeFilter get Nashville => AwesomeFilter(
        name: 'Nashville',
        previewFilter: ColorFilter.matrix(
          PresetFilters.nashville.matrix,
        ),
        outputFilter: PhotoFilters.NashvilleFilter(),
      );
  static AwesomeFilter get Perpetua => AwesomeFilter(
        name: 'Perpetua',
        previewFilter: ColorFilter.matrix(
          PresetFilters.perpetua.matrix,
        ),
        outputFilter: PhotoFilters.PerpetuaFilter(),
      );
  static AwesomeFilter get Reyes => AwesomeFilter(
        name: 'Reyes',
        previewFilter: ColorFilter.matrix(
          PresetFilters.reyes.matrix,
        ),
        outputFilter: PhotoFilters.ReyesFilter(),
      );
  static AwesomeFilter get Rise => AwesomeFilter(
        name: 'Rise',
        previewFilter: ColorFilter.matrix(
          PresetFilters.rise.matrix,
        ),
        outputFilter: PhotoFilters.RiseFilter(),
      );
  static AwesomeFilter get Sierra => AwesomeFilter(
        name: 'Sierra',
        previewFilter: ColorFilter.matrix(
          PresetFilters.sierra.matrix,
        ),
        outputFilter: PhotoFilters.SierraFilter(),
      );
  static AwesomeFilter get Skyline => AwesomeFilter(
        name: 'Skyline',
        previewFilter: ColorFilter.matrix(
          PresetFilters.skyline.matrix,
        ),
        outputFilter: PhotoFilters.SkylineFilter(),
      );
  static AwesomeFilter get Slumber => AwesomeFilter(
        name: 'Slumber',
        previewFilter: ColorFilter.matrix(
          PresetFilters.slumber.matrix,
        ),
        outputFilter: PhotoFilters.SlumberFilter(),
      );
  static AwesomeFilter get Stinson => AwesomeFilter(
        name: 'Stinson',
        previewFilter: ColorFilter.matrix(
          PresetFilters.stinson.matrix,
        ),
        outputFilter: PhotoFilters.StinsonFilter(),
      );
  static AwesomeFilter get Sutro => AwesomeFilter(
        name: 'Sutro',
        previewFilter: ColorFilter.matrix(
          PresetFilters.sutro.matrix,
        ),
        outputFilter: PhotoFilters.SutroFilter(),
      );
  static AwesomeFilter get Toaster => AwesomeFilter(
        name: 'Toaster',
        previewFilter: ColorFilter.matrix(
          PresetFilters.toaster.matrix,
        ),
        outputFilter: PhotoFilters.ToasterFilter(),
      );
  static AwesomeFilter get Valencia => AwesomeFilter(
        name: 'Valencia',
        previewFilter: ColorFilter.matrix(
          PresetFilters.valencia.matrix,
        ),
        outputFilter: PhotoFilters.ValenciaFilter(),
      );
  static AwesomeFilter get Vesper => AwesomeFilter(
        name: 'Vesper',
        previewFilter: ColorFilter.matrix(
          PresetFilters.vesper.matrix,
        ),
        outputFilter: PhotoFilters.VesperFilter(),
      );
  static AwesomeFilter get Walden => AwesomeFilter(
        name: 'Walden',
        previewFilter: ColorFilter.matrix(ColorFilterGenerator(
          name: "Walden",
          filters: [
            ColorFilterAddons.brightness(0.1),
            ColorFilterAddons.addictiveColor(45, 45, 0),
          ],
        ).matrix),
        outputFilter: PhotoFilters.WaldenFilter(),
      );
  static AwesomeFilter get Willow => AwesomeFilter(
        name: 'Willow',
        previewFilter: ColorFilter.matrix(
          PresetFilters.willow.matrix,
        ),
        outputFilter: PhotoFilters.WillowFilter(),
      );
  static AwesomeFilter get XProII => AwesomeFilter(
        name: 'X-Pro II',
        previewFilter: ColorFilter.matrix(
          ColorFilterGenerator(
            name: "X-Pro II",
            filters: [
              ColorFilterAddons.addictiveColor(30, 30, 0),
              ColorFilterAddons.saturation(0.2),
              ColorFilterAddons.contrast(0.2),
              ColorFilterAddons.hue(0.03),
              ColorFilterAddons.brightness(0.04),
            ],
          ).matrix,
        ),
        outputFilter: PhotoFilters.XProIIFilter(),
      );
}
