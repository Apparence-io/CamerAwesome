import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/src/layouts/awesome/widgets/utils/awesome_circle_icon_button.dart';
import 'package:flutter/material.dart';

class AwesomeFilterSelector extends StatefulWidget {
  final CameraState state;

  const AwesomeFilterSelector({
    super.key,
    required this.state,
  });

  @override
  State<AwesomeFilterSelector> createState() => _AwesomeFilterSelectorState();
}

class _AwesomeFilterSelectorState extends State<AwesomeFilterSelector> {
  int? _textureId;

  @override
  void initState() {
    super.initState();

    widget.state.textureId().then((textureId) {
      setState(() {
        _textureId = textureId;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AwesomeCircleButton(
      icon: Icons.filter_rounded,
      onTap: () {},
    );
  }
}
