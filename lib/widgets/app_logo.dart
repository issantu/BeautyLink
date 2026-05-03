import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

enum AppLogoSize { small, medium, large, xlarge }

class AppLogo extends StatelessWidget {
  final AppLogoSize size;
  final bool showName;
  final bool showTagline;

  const AppLogo({
    super.key,
    this.size = AppLogoSize.medium,
    this.showName = false,
    this.showTagline = false,
  });

  double get _boxSize => switch (size) {
        AppLogoSize.small  => 40,
        AppLogoSize.medium => 64,
        AppLogoSize.large  => 90,
        AppLogoSize.xlarge => 110,
      };

  double get _fontSize => switch (size) {
        AppLogoSize.small  => 16,
        AppLogoSize.medium => 24,
        AppLogoSize.large  => 34,
        AppLogoSize.xlarge => 42,
      };

  double get _radius => _boxSize * 0.26;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LogoBox(boxSize: _boxSize, fontSize: _fontSize, radius: _radius),
        if (showName) ...[
          SizedBox(height: _boxSize * 0.2),
          _LogoName(size: size),
        ],
        if (showTagline) ...[
          const SizedBox(height: 6),
          const Text(
            'Films • TV Direct • Jeux',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _LogoBox extends StatelessWidget {
  final double boxSize;
  final double fontSize;
  final double radius;

  const _LogoBox({
    required this.boxSize,
    required this.fontSize,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9C6FFF), Color(0xFF7C4DFF), Color(0xFF5B2FD4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.45),
            blurRadius: boxSize * 0.35,
            spreadRadius: boxSize * 0.04,
            offset: Offset(0, boxSize * 0.08),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle inner highlight
          Positioned(
            top: 2,
            left: 2,
            child: Container(
              width: boxSize * 0.55,
              height: boxSize * 0.3,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(radius - 2),
                  bottomRight: Radius.circular(radius * 0.5),
                ),
              ),
            ),
          ),
          // "OF" monogram
          Center(
            child: Text(
              'OF',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1.5,
                height: 1,
              ),
            ),
          ),
          // Bottom-right dot accent
          Positioned(
            bottom: boxSize * 0.12,
            right: boxSize * 0.12,
            child: Container(
              width: boxSize * 0.12,
              height: boxSize * 0.12,
              decoration: const BoxDecoration(
                color: AppColors.live,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoName extends StatelessWidget {
  final AppLogoSize size;
  const _LogoName({required this.size});

  double get _nameFontSize => switch (size) {
        AppLogoSize.small  => 18,
        AppLogoSize.medium => 26,
        AppLogoSize.large  => 36,
        AppLogoSize.xlarge => 48,
      };

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) =>
          AppColors.primaryGradient.createShader(bounds),
      child: Text(
        'OmniFlix',
        style: TextStyle(
          fontSize: _nameFontSize,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
