import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/src/orchestrator/models/filters/awesome_filters.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AwesomeFilterSelector extends StatefulWidget {
  final CameraState state;
  final FilterListPosition filterListPosition;
  final Widget indicator;
  final EdgeInsets? filterListPadding;
  final Color? filterListBackgroundColor;

  const AwesomeFilterSelector({
    super.key,
    required this.state,
    required this.filterListPosition,
    required this.filterListPadding,
    required this.filterListBackgroundColor,
    required this.indicator,
  });

  @override
  State<AwesomeFilterSelector> createState() => _AwesomeFilterSelectorState();
}

class _AwesomeFilterSelectorState extends State<AwesomeFilterSelector> {
  final CarouselController _controller = CarouselController();
  int? _textureId;
  int _selected = 0;

  List<String> get presetsIds =>
      awesomePresetFiltersList.map((e) => e.id).toList();

  @override
  void initState() {
    super.initState();

    _selected = presetsIds.indexOf(widget.state.filter.id);

    widget.state.textureId().then((textureId) {
      setState(() {
        _textureId = textureId;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final children = [
      widget.indicator,
      Container(
        padding: widget.filterListPadding,
        color: widget.filterListBackgroundColor,
        child: Stack(
          children: [
            CarouselSlider(
              options: CarouselOptions(
                height: 60.0,
                initialPage: _selected,
                onPageChanged: (index, reason) {
                  final filter = awesomePresetFiltersList[index];

                  setState(() {
                    _selected = index;
                  });

                  HapticFeedback.selectionClick();
                  widget.state.setFilter(filter);
                },
                enableInfiniteScroll: false,
                viewportFraction: 0.165,
              ),
              carouselController: _controller,
              items: awesomePresetFiltersList.map((filter) {
                return Builder(
                  builder: (BuildContext context) {
                    return AwesomeBouncingWidget(
                      onTap: () {
                        _controller.animateToPage(
                          presetsIds.indexOf(filter.id),
                          curve: Curves.fastLinearToSlowEaseIn,
                          duration: const Duration(milliseconds: 700),
                        );
                      },
                      child: _FilterPreview(
                        filter: filter.preview,
                        textureId: _textureId,
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            IgnorePointer(
              child: Center(
                child: Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: const BorderRadius.all(Radius.circular(9)),
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ];
    return Column(
      children: widget.filterListPosition == FilterListPosition.belowButton
          ? children
          : children.reversed.toList(),
    );
  }
}

class _FilterPreview extends StatelessWidget {
  final ColorFilter filter;
  final int? textureId;

  const _FilterPreview({
    Key? key,
    required this.filter,
    required this.textureId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(9)),
      child: SizedBox(
        width: 60,
        height: 60,
        child: textureId != null
            ? ColorFiltered(
                colorFilter: filter,
                child: OverflowBox(
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: 60,
                      // TODO: maybe this is inverted on Android ??
                      height: 60 / (9 / 16),
                      child: Texture(textureId: textureId!),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
