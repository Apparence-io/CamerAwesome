import 'package:camerawesome/src/widgets/widgets.dart';
import 'package:flutter/material.dart';

class AwesomeCameraFloatingPreview extends StatefulWidget {
  final Texture texture;
  final int index;
  const AwesomeCameraFloatingPreview({
    Key? key,
    required this.index,
    required this.texture,
  }) : super(key: key);

  @override
  State<AwesomeCameraFloatingPreview> createState() =>
      _AwesomeCameraFloatingPreviewState();
}

class _AwesomeCameraFloatingPreviewState
    extends State<AwesomeCameraFloatingPreview> {
  Offset? _position;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _position = Offset(
          widget.index * 20,
          MediaQuery.of(context).padding.top + 60 + (widget.index * 20),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _position != null
        ? Positioned(
            left: _position!.dx,
            top: _position!.dy,
            child: AwesomeBouncingWidget(
              onTap: () {},
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _position = Offset(
                      _position!.dx + details.delta.dx,
                      _position!.dy + details.delta.dy,
                    );
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        spreadRadius: 10,
                        blurRadius: 20,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 200,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 9 / 16,
                          child: widget.texture,
                        ),
                      ),
                      // child: frontPreviewTexture,
                    ),
                  ),
                ),
              ),
            ),
          )
        : const SizedBox();
  }
}
