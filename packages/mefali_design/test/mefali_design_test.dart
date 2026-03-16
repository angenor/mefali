import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_design/mefali_design.dart';

void main() {
  group('MefaliTheme', () {
    test('light() returns a valid ThemeData with M3', () {
      final theme = MefaliTheme.light();
      expect(theme, isA<ThemeData>());
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
    });

    test('dark() returns a valid ThemeData with M3', () {
      final theme = MefaliTheme.dark();
      expect(theme, isA<ThemeData>());
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
    });

    test('light theme uses marron primary color', () {
      final theme = MefaliTheme.light();
      expect(theme.colorScheme.primary, MefaliColors.primaryLight);
    });

    test('dark theme uses marron primary color', () {
      final theme = MefaliTheme.dark();
      expect(theme.colorScheme.primary, MefaliColors.primaryDark);
    });
  });

  group('MefaliColors', () {
    test('primary light is Brown 700', () {
      expect(MefaliColors.primaryLight, const Color(0xFF5D4037));
    });

    test('primary dark is Brown 100', () {
      expect(MefaliColors.primaryDark, const Color(0xFFD7CCC8));
    });

    test('success light is green', () {
      expect(MefaliColors.successLight, const Color(0xFF4CAF50));
    });
  });

  group('MefaliTypography', () {
    test('textTheme has correct body minimum sizes', () {
      final textTheme = MefaliTypography.textTheme;
      expect(textTheme.bodyMedium?.fontSize, 14);
      expect(textTheme.bodySmall?.fontSize, 12);
      expect(textTheme.labelMedium?.fontSize, 12);
    });
  });
}
