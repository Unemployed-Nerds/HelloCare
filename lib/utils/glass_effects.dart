import 'package:flutter/material.dart';

class GlassEffects {
  // Glass morphism decoration with neon glow
  static BoxDecoration glassMorphism({
    required Color baseColor,
    Color? glowColor,
    double opacity = 0.3,
    double blurRadius = 20.0,
    double spreadRadius = 0.0,
    double borderWidth = 1.5,
    double borderRadius = 16.0,
    List<Color>? gradientColors,
  }) {
    final effectiveGlowColor = glowColor ?? baseColor;
    
    return BoxDecoration(
      gradient: gradientColors != null
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            )
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor.withOpacity(opacity),
                baseColor.withOpacity(opacity * 0.6),
              ],
            ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.1),
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: effectiveGlowColor.withOpacity(0.4),
          blurRadius: blurRadius,
          spreadRadius: spreadRadius,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: blurRadius * 0.5,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // Neon glow decoration for containers
  static BoxDecoration neonGlow({
    required Color glowColor,
    double blurRadius = 12.0,
    double spreadRadius = 2.0,
    double borderRadius = 16.0,
    Color? backgroundColor,
    double backgroundOpacity = 0.2,
  }) {
    return BoxDecoration(
      color: backgroundColor?.withOpacity(backgroundOpacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: glowColor.withOpacity(0.5),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: glowColor.withOpacity(0.6),
          blurRadius: blurRadius,
          spreadRadius: spreadRadius,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: glowColor.withOpacity(0.3),
          blurRadius: blurRadius * 2,
          spreadRadius: spreadRadius * 2,
          offset: const Offset(0, 0),
        ),
      ],
    );
  }

  // Pulsing neon dot indicator
  static Widget neonDot({
    required Color color,
    double size = 8.0,
    double blurRadius = 8.0,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.8),
            blurRadius: blurRadius,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  // Glass card with neon accent
  static BoxDecoration glassCard({
    required Color primaryColor,
    Color? accentColor,
    double opacity = 0.15,
    double borderRadius = 24.0,
  }) {
    final accent = accentColor ?? primaryColor;
    
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryColor.withOpacity(opacity),
          primaryColor.withOpacity(opacity * 0.6),
        ],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.1),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: accent.withOpacity(0.3),
          blurRadius: 20,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // Gradient button with neon glow
  static BoxDecoration neonButton({
    required List<Color> gradientColors,
    double borderRadius = 20.0,
    double blurRadius = 12.0,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: gradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.3),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: gradientColors.first.withOpacity(0.4),
          blurRadius: blurRadius,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

