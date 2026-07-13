import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/mefali_core.dart';

void main() {
  test('MefaliTheme.light reflète les tokens couleur', () {
    final theme = MefaliTheme.light;
    expect(theme.colorScheme.primary, MefaliTokens.primary);
    expect(theme.colorScheme.error, MefaliTokens.danger);
    expect(theme.scaffoldBackgroundColor, MefaliTokens.background);
  });

  test('MefaliTheme.light utilise Inter et l\'échelle typographique', () {
    final t = MefaliTheme.light.textTheme;
    expect(t.bodyLarge?.fontFamily, MefaliTokens.fontFamily);
    expect(t.bodyLarge?.fontSize, MefaliTokens.bodySize); // 16
    expect(t.displayLarge?.fontSize, MefaliTokens.displaySize); // 40
    expect(t.titleLarge?.fontSize, MefaliTokens.titleSize); // 22
  });

  test('MefaliTheme.light applique le rayon de carte des tokens', () {
    final shape = MefaliTheme.light.cardTheme.shape! as RoundedRectangleBorder;
    final radius = shape.borderRadius as BorderRadius;
    expect(radius.topLeft.x, MefaliTokens.radiusCard); // 16
  });
}
