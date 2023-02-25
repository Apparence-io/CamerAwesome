import 'dart:typed_data';

///The [Filter] class to define a Filter consists of multiple [SubFilter]s
abstract class Filter extends Object {
  final String name;
  const Filter({required this.name});

  ///Apply the [SubFilter] to an Image.
  void apply(Uint8List pixels, int width, int height);
}

///The [SubFilter] class is the abstract class to define any SubFilter.
abstract class SubFilter extends Object {}
