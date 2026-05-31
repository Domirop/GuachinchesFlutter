import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';

class FloatingCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final String? identifier;

  const FloatingCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.identifier,
  });

  @override
  Widget build(BuildContext context) {
    final gesture = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.glassDark,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: iconColor ?? Colors.white),
      ),
    );
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: identifier != null
            ? Semantics(identifier: identifier!, button: true, child: gesture)
            : gesture,
      ),
    );
  }
}

class DetailFloatingButtons extends StatelessWidget {
  final bool isSaved;
  final VoidCallback onBack;
  final VoidCallback onToggleSave;
  final String? backIdentifier;
  final String? saveIdentifier;

  const DetailFloatingButtons({
    super.key,
    required this.isSaved,
    required this.onBack,
    required this.onToggleSave,
    this.backIdentifier,
    this.saveIdentifier,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 8;
    return Stack(
      children: [
        Positioned(
          top: top,
          left: 12,
          child: FloatingCircleButton(
            icon: Icons.arrow_back_ios_new,
            onTap: onBack,
            identifier: backIdentifier,
          ),
        ),
        Positioned(
          top: top,
          right: 12,
          child: FloatingCircleButton(
            icon: isSaved ? Icons.favorite : Icons.favorite_border,
            iconColor: isSaved ? AppColors.mojo : Colors.white,
            onTap: onToggleSave,
            identifier: saveIdentifier,
          ),
        ),
      ],
    );
  }
}
