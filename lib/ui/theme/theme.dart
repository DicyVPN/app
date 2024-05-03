import 'package:dicyvpn/ui/theme/colors.dart';
import 'package:flutter/material.dart';

ColorScheme customColorScheme = ColorScheme.fromSeed(
  seedColor: CustomColors.gray,
  brightness: Brightness.dark,
  primary: CustomColors.blue.shade500,
  onPrimary: Colors.white,
  secondary: CustomColors.gray.shade200,
  secondaryContainer: CustomColors.gray.shade500,
  onSecondaryContainer: Colors.white,
  tertiary: CustomColors.gray.shade900,
  // ignore: deprecated_member_use -- it's the only property that actually changes the screen background
  background: CustomColors.gray.shade500,
  surface: CustomColors.gray.shade700,
  onSurface: Colors.white, // Also text inside text fields
  surfaceContainerHighest: CustomColors.gray.shade800, // Also text field background
  onSurfaceVariant: CustomColors.gray.shade200, // Also text fields labels
  error: CustomColors.red.shade300,
);
