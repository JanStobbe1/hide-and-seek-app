import 'package:flutter/material.dart';

enum StobbeSeason { spring, summer, autumn, winter }

StobbeSeason stobbeSeasonForDate([DateTime? date]) {
  final month = (date ?? DateTime.now()).month;
  if (month >= 3 && month <= 5) return StobbeSeason.spring;
  if (month >= 6 && month <= 8) return StobbeSeason.summer;
  if (month >= 9 && month <= 11) return StobbeSeason.autumn;
  return StobbeSeason.winter;
}

class SeasonalStobbe extends StatefulWidget {
  const SeasonalStobbe({
    required this.assetPath,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
    this.semanticLabel,
    super.key,
  });

  final String assetPath;
  final double? height;
  final double? width;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  State<SeasonalStobbe> createState() => _SeasonalStobbeState();
}

class _SeasonalStobbeState extends State<SeasonalStobbe>
    with SingleTickerProviderStateMixin {
  late final AnimationController _snowController;
  late final StobbeSeason season;

  @override
  void initState() {
    super.initState();
    season = stobbeSeasonForDate();
    _snowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (season != StobbeSeason.winter) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _snowController.stop();
    } else if (!_snowController.isAnimating) {
      _snowController.repeat();
    }
  }

  @override
  void dispose() {
    _snowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.height ?? 180;
    final width = widget.width ?? height;
    return SizedBox(
      height: widget.height,
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Image.asset(
            widget.assetPath,
            height: widget.height,
            width: widget.width,
            fit: widget.fit,
            semanticLabel: widget.semanticLabel,
          ),
          IgnorePointer(child: _seasonDecoration(context, height, width)),
        ],
      ),
    );
  }

  Widget _seasonDecoration(BuildContext context, double height, double width) {
    switch (season) {
      case StobbeSeason.spring:
        return Stack(
          children: [
            _flower(const Color(0xfff1b6c8),
                top: height * .15, left: width * .1),
            _flower(const Color(0xfff5d18a),
                top: height * .28, right: width * .08),
          ],
        );
      case StobbeSeason.summer:
        return Stack(
          children: [
            Positioned(
              bottom: height * .08,
              left: width * .08,
              child: Icon(
                Icons.eco,
                size: width * .16,
                color: const Color(0x885a8b57),
              ),
            ),
          ],
        );
      case StobbeSeason.autumn:
        return Stack(
          children: [
            _leaf(const Color(0xffc65d38),
                bottom: height * .04, left: width * .08, angle: -.3),
            _leaf(const Color(0xffe19b3e),
                bottom: height * .02, right: width * .1, angle: .25),
            _leaf(const Color(0xffd2b44c),
                bottom: height * .12, left: width * .7, angle: .5),
            Positioned(
              right: width * .03,
              top: height * .35,
              child: Icon(
                Icons.water_drop,
                size: width * .1,
                color: const Color(0x665b86a4),
              ),
            ),
          ],
        );
      case StobbeSeason.winter:
        return AnimatedBuilder(
          animation: _snowController,
          builder: (context, child) => Stack(
            children: [
              Positioned(
                top: height * .12,
                left: width * .2,
                right: width * .2,
                child: Container(
                  height: height * .045,
                  decoration: BoxDecoration(
                    color: const Color(0xfff7fafb),
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: const [
                      BoxShadow(color: Color(0x22000000), blurRadius: 2),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: height * .26,
                left: width * .32,
                child: Container(
                  width: width * .36,
                  height: height * .055,
                  decoration: BoxDecoration(
                    color: const Color(0xffa83d3d),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Positioned(
                top: height * (.18 + (_snowController.value * .42)),
                right: width * .12,
                child: Icon(
                  Icons.ac_unit,
                  size: width * .12,
                  color: const Color(0xbbffffff),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _flower(Color color, {double? top, double? left, double? right}) =>
      Positioned(
        top: top,
        left: left,
        right: right,
        child: Icon(Icons.local_florist, size: 14, color: color),
      );

  Widget _leaf(
    Color color, {
    required double bottom,
    required double angle,
    double? left,
    double? right,
  }) =>
      Positioned(
        bottom: bottom,
        left: left,
        right: right,
        child: Transform.rotate(
          angle: angle,
          child: Icon(Icons.eco, size: 15, color: color),
        ),
      );
}
