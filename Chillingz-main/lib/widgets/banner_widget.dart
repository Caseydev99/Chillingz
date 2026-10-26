import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_icons.dart';
import '../core/utils/extensions.dart';

class BannerWidget extends StatelessWidget {
  const BannerWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.searchHint,
    this.searchController,
    this.onSearchChanged,
    this.onFilterTap,
  });

  final String title;
  final String subtitle;
  final String searchHint;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 335 / 150,
        child: CustomPaint(
          painter: const _BannerBackgroundPainter(),
          child: Stack(
            children: [
              const Positioned(
                top: 12,
                right: 14,
                child: _SparklesDecoration(),
              ),
              const Positioned(
                top: 58,
                right: 62,
                child: _MusicChip(),
              ),
              const Positioned(
                top: 40,
                right: 36,
                child: Icon(
                  Icons.music_note_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 13, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                          height: 1.1,
                        ),
                      ),
                      6.vSpace,
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xE6FFFFFF),
                          height: 1.2,
                        ),
                      ),
                      const Spacer(),
                      _BannerSearchBar(
                        hint: searchHint,
                        controller: searchController,
                        onChanged: onSearchChanged,
                        onFilterTap: onFilterTap,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerSearchBar extends StatelessWidget {
  const _BannerSearchBar({
    required this.hint,
    this.controller,
    this.onChanged,
    this.onFilterTap,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 50,
        padding: const EdgeInsets.only(left: 12, right: 8),
        child: Row(
          children: [
            const Icon(
              AppIcons.search,
              size: 20,
              color: Color(0xFF4A4A4A),
            ),
            10.hSpace,
            Expanded(
              child: CupertinoTheme(
                data: const CupertinoThemeData(
                  primaryColor: AppColors.primary,
                ),
                child: CupertinoTextField(
                  controller: controller,
                  onChanged: onChanged,
                  autocorrect: false,
                  enableSuggestions: false,
                  smartDashesType: SmartDashesType.disabled,
                  smartQuotesType: SmartQuotesType.disabled,
                  padding: EdgeInsets.zero,
                  maxLines: 1,
                  cursorColor: AppColors.primary,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF4A4A4A),
                    height: 1.2,
                  ),
                  placeholder: hint,
                  placeholderStyle: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFADADAD),
                    height: 1.2,
                  ),
                  decoration: null,
                ),
              ),
            ),
            GestureDetector(
              onTap: onFilterTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8E4FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppIcons.tune,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MusicChip extends StatelessWidget {
  const _MusicChip();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -12 * math.pi / 180,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0x30FFFFFF),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: const Color(0xCCFFFFFF),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.music_note_rounded,
          size: 16,
          color: Colors.white70,
        ),
      ),
    );
  }
}

class _SparklesDecoration extends StatelessWidget {
  const _SparklesDecoration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 30,
      child: Stack(
        children: const [
          Positioned(
            left: 0,
            top: 6,
            child: Icon(
              Icons.auto_awesome,
              size: 22,
              color: Colors.white,
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Icon(
              Icons.auto_awesome,
              size: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerBackgroundPainter extends CustomPainter {
  const _BannerBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFA34FE5),
          Color(0xFF8D2DE2),
          Color(0xFF7427C7),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, background);

    final leftTop = Paint()..color = const Color(0xFF9A47E2);
    final leftBottom = Paint()..color = const Color(0xFF6F2DAE);
    final leftFront = Paint()..color = const Color(0xFF8B2BE0);
    final rightTop = Paint()..color = const Color(0xFF9350D8);
    final rightLeft = Paint()..color = const Color(0xFF7030A9);
    final rightFront = Paint()..color = const Color(0xFF942BEE);
    final rightSide = Paint()..color = const Color(0xFF6D2BAA);

    final leftTopPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.28, 0)
      ..lineTo(size.width * 0.40, size.height * 0.12)
      ..lineTo(size.width * 0.40, size.height * 0.62)
      ..lineTo(size.width * 0.16, size.height * 0.44)
      ..lineTo(0, size.height * 0.26)
      ..close();
    canvas.drawPath(leftTopPath, leftTop);

    final leftBottomPath = Path()
      ..moveTo(0, size.height * 0.26)
      ..lineTo(size.width * 0.16, size.height * 0.44)
      ..lineTo(size.width * 0.16, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(leftBottomPath, leftBottom);

    final leftFrontPath = Path()
      ..moveTo(size.width * 0.16, size.height * 0.44)
      ..lineTo(size.width * 0.40, size.height * 0.62)
      ..lineTo(size.width * 0.40, size.height)
      ..lineTo(size.width * 0.16, size.height)
      ..close();
    canvas.drawPath(leftFrontPath, leftFront);

    final rightTopPath = Path()
      ..moveTo(size.width * 0.60, 0)
      ..lineTo(size.width * 0.88, 0)
      ..lineTo(size.width, size.height * 0.22)
      ..lineTo(size.width * 0.74, size.height * 0.22)
      ..close();
    canvas.drawPath(rightTopPath, rightTop);

    final rightLeftPath = Path()
      ..moveTo(size.width * 0.60, 0)
      ..lineTo(size.width * 0.74, size.height * 0.22)
      ..lineTo(size.width * 0.74, size.height * 0.54)
      ..lineTo(size.width * 0.60, size.height * 0.35)
      ..close();
    canvas.drawPath(rightLeftPath, rightLeft);

    final rightFrontPath = Path()
      ..moveTo(size.width * 0.74, size.height * 0.22)
      ..lineTo(size.width * 0.85, size.height * 0.08)
      ..lineTo(size.width * 0.85, size.height * 0.58)
      ..lineTo(size.width * 0.74, size.height * 0.54)
      ..close();
    canvas.drawPath(rightFrontPath, rightFront);

    final rightSidePath = Path()
      ..moveTo(size.width * 0.85, size.height * 0.08)
      ..lineTo(size.width, size.height * 0.22)
      ..lineTo(size.width, size.height * 0.72)
      ..lineTo(size.width * 0.85, size.height * 0.58)
      ..close();
    canvas.drawPath(rightSidePath, rightSide);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
