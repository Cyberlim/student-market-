import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double borderWidth;
  final bool showBorder;

  const GlassCard({
    Key? key,
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 16.0,
    this.opacity = 0.08,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.color,
    this.borderWidth = 1.0,
    this.showBorder = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Choose base glass color
    final baseColor = color ?? 
        (isDark 
            ? Colors.white.withOpacity(opacity * 0.5) 
            : Colors.black.withOpacity(opacity));
            
    final borderGrad = isDark 
        ? AppColors.glassBorderDarkGradient 
        : AppColors.glassBorderGradient;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.3) 
                : Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: CustomPaint(
            painter: showBorder 
                ? _GradientBorderPainter(
                    borderRadius: borderRadius,
                    borderWidth: borderWidth,
                    gradient: borderGrad,
                  )
                : null,
            child: Container(
              padding: padding,
              color: baseColor,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final double borderRadius;
  final double borderWidth;
  final Gradient gradient;

  _GradientBorderPainter({
    required this.borderRadius,
    required this.borderWidth,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..shader = gradient.createShader(rect);

    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.gradient != gradient;
  }
}
