import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_design/mefali_design.dart';

/// Relative luminance per WCAG 2.0.
double _relativeLuminance(Color c) {
  double linearize(double s) {
    return s <= 0.04045
        ? s / 12.92
        : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * linearize(c.r) +
      0.7152 * linearize(c.g) +
      0.0722 * linearize(c.b);
}

/// WCAG contrast ratio between two colors.
double _contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  // ─── MefaliTheme ─────────────────────────────────────────
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

    test('light theme surface colors are correct', () {
      final cs = MefaliTheme.light().colorScheme;
      expect(cs.surface, MefaliColors.surfaceLight);
      expect(cs.onSurface, MefaliColors.onSurfaceLight);
    });

    test('dark theme surface colors are correct', () {
      final cs = MefaliTheme.dark().colorScheme;
      expect(cs.surface, MefaliColors.surfaceDark);
      expect(cs.onSurface, MefaliColors.onSurfaceDark);
    });

    test('light theme error color is correct', () {
      expect(MefaliTheme.light().colorScheme.error, MefaliColors.errorLight);
    });

    test('dark theme error color is correct', () {
      expect(MefaliTheme.dark().colorScheme.error, MefaliColors.errorDark);
    });
  });

  // ─── MefaliCustomColors ThemeExtension ───────────────────
  group('MefaliCustomColors', () {
    test('light theme includes MefaliCustomColors extension', () {
      final theme = MefaliTheme.light();
      final custom = theme.extension<MefaliCustomColors>();
      expect(custom, isNotNull);
      expect(custom!.success, MefaliColors.successLight);
      expect(custom.onSuccess, MefaliColors.onSuccessLight);
      expect(custom.successContainer, MefaliColors.successContainerLight);
      expect(custom.onSuccessContainer, MefaliColors.onSuccessContainerLight);
      expect(custom.warning, MefaliColors.warningLight);
    });

    test('dark theme includes MefaliCustomColors extension', () {
      final theme = MefaliTheme.dark();
      final custom = theme.extension<MefaliCustomColors>();
      expect(custom, isNotNull);
      expect(custom!.success, MefaliColors.successDark);
      expect(custom.onSuccess, MefaliColors.onSuccessDark);
      expect(custom.successContainer, MefaliColors.successContainerDark);
      expect(custom.onSuccessContainer, MefaliColors.onSuccessContainerDark);
      expect(custom.warning, MefaliColors.warningDark);
    });

    test('copyWith preserves unchanged values', () {
      const original = MefaliCustomColors.light;
      final copy = original.copyWith(success: Colors.red);
      expect(copy.success, Colors.red);
      expect(copy.onSuccess, original.onSuccess);
      expect(copy.warning, original.warning);
    });

    test('lerp interpolates correctly at t=0', () {
      const a = MefaliCustomColors.light;
      const b = MefaliCustomColors.dark;
      final result = a.lerp(b, 0);
      expect(result.success, a.success);
    });

    test('lerp interpolates correctly at t=1', () {
      const a = MefaliCustomColors.light;
      const b = MefaliCustomColors.dark;
      final result = a.lerp(b, 1);
      expect(result.success, b.success);
    });

    test('lerp returns self when other is null', () {
      const a = MefaliCustomColors.light;
      final result = a.lerp(null, 0.5);
      expect(result.success, a.success);
    });
  });

  // ─── MefaliColors ────────────────────────────────────────
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

    test('success dark is lighter green', () {
      expect(MefaliColors.successDark, const Color(0xFF81C784));
    });

    test('seedColor matches primaryLight', () {
      expect(MefaliColors.seedColor, MefaliColors.primaryLight);
    });

    test('warning colors are defined', () {
      expect(MefaliColors.warningLight, const Color(0xFFFF9800));
      expect(MefaliColors.warningDark, const Color(0xFFFFCC80));
    });

    test('success container colors are defined', () {
      expect(MefaliColors.successContainerLight, const Color(0xFFC8E6C9));
      expect(MefaliColors.successContainerDark, const Color(0xFF2E7D32));
    });
  });

  // ─── MefaliTypography ────────────────────────────────────
  group('MefaliTypography', () {
    test('textTheme has correct body minimum sizes', () {
      final textTheme = MefaliTypography.textTheme;
      expect(textTheme.bodyMedium?.fontSize, 14);
      expect(textTheme.bodySmall?.fontSize, 12);
      expect(textTheme.labelMedium?.fontSize, 12);
    });

    test('bodyLarge is at least 14sp', () {
      final size = MefaliTypography.textTheme.bodyLarge?.fontSize ?? 0;
      expect(size, greaterThanOrEqualTo(14));
    });

    test('labelLarge is at least 12sp', () {
      final size = MefaliTypography.textTheme.labelLarge?.fontSize ?? 0;
      expect(size, greaterThanOrEqualTo(12));
    });
  });

  // ─── Touch targets (>= 48dp) ────────────────────────────
  group('Touch targets', () {
    test('FilledButton minimum height is >= 48', () {
      final theme = MefaliTheme.light();
      final style = theme.filledButtonTheme.style!;
      final minSize = style.minimumSize!.resolve({});
      expect(minSize!.height, greaterThanOrEqualTo(48));
    });

    test('OutlinedButton minimum height is >= 48', () {
      final theme = MefaliTheme.light();
      final style = theme.outlinedButtonTheme.style!;
      final minSize = style.minimumSize!.resolve({});
      expect(minSize!.height, greaterThanOrEqualTo(48));
    });

    test('TextButton minimum height is >= 48', () {
      final theme = MefaliTheme.light();
      final style = theme.textButtonTheme.style!;
      final minSize = style.minimumSize!.resolve({});
      expect(minSize!.height, greaterThanOrEqualTo(48));
    });

    test('ElevatedButton minimum height is >= 48', () {
      final theme = MefaliTheme.light();
      final style = theme.elevatedButtonTheme.style!;
      final minSize = style.minimumSize!.resolve({});
      expect(minSize!.height, greaterThanOrEqualTo(48));
    });

    test('IconButton minimum size is >= 48x48', () {
      final theme = MefaliTheme.light();
      final style = theme.iconButtonTheme.style!;
      final minSize = style.minimumSize!.resolve({});
      expect(minSize!.width, greaterThanOrEqualTo(48));
      expect(minSize.height, greaterThanOrEqualTo(48));
    });
  });

  // ─── Component themes configurees ───────────────────────
  group('Component themes', () {
    test('CardTheme has rounded shape', () {
      final theme = MefaliTheme.light();
      expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
    });

    test('CardTheme light elevation is 1', () {
      expect(MefaliTheme.light().cardTheme.elevation, 1);
    });

    test('CardTheme dark elevation is 0', () {
      expect(MefaliTheme.dark().cardTheme.elevation, 0);
    });

    test('NavigationBarTheme is configured', () {
      final theme = MefaliTheme.light();
      expect(theme.navigationBarTheme.height, 64);
    });

    test('TabBarTheme uses primary indicator', () {
      final theme = MefaliTheme.light();
      expect(theme.tabBarTheme.indicatorColor, MefaliColors.primaryLight);
    });

    test('InputDecorationTheme has outlined border', () {
      final theme = MefaliTheme.light();
      expect(theme.inputDecorationTheme.border, isA<OutlineInputBorder>());
    });

    test('InputDecorationTheme labels always float', () {
      final theme = MefaliTheme.light();
      expect(
        theme.inputDecorationTheme.floatingLabelBehavior,
        FloatingLabelBehavior.always,
      );
    });

    test('SnackBarTheme is floating', () {
      final theme = MefaliTheme.light();
      expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
    });

    test('ChipTheme has rounded shape', () {
      final theme = MefaliTheme.light();
      expect(theme.chipTheme.shape, isA<RoundedRectangleBorder>());
    });

    test('BadgeTheme sizes are configured', () {
      final theme = MefaliTheme.light();
      expect(theme.badgeTheme.smallSize, 8);
      expect(theme.badgeTheme.largeSize, 16);
    });

    test('materialTapTargetSize is padded', () {
      final theme = MefaliTheme.light();
      expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
    });
  });

  // ─── VendorStatusIndicator ──────────────────────────────
  group('VendorStatusIndicator', () {
    testWidgets('displays correct text for each status', (tester) async {
      for (final status in VendorStatus.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VendorStatusIndicator(status: status),
            ),
          ),
        );
        expect(find.text(status.label), findsOneWidget);
      }
    });

    testWidgets('displays correct icon for each status', (tester) async {
      for (final status in VendorStatus.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VendorStatusIndicator(status: status),
            ),
          ),
        );
        expect(find.byIcon(status.icon), findsOneWidget);
      }
    });

    testWidgets('read-only mode does not open bottom sheet on tap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VendorStatusIndicator(status: VendorStatus.open),
          ),
        ),
      );

      await tester.tap(find.text('Ouvert'));
      await tester.pumpAndSettle();

      // No bottom sheet should appear
      expect(find.text('Changer mon statut'), findsNothing);
    });

    testWidgets('interactive mode opens bottom sheet on tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VendorStatusIndicator(
              status: VendorStatus.open,
              interactive: true,
              onStatusChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ouvert'));
      await tester.pumpAndSettle();

      expect(find.text('Changer mon statut'), findsOneWidget);
      expect(find.text('Ouvert'), findsWidgets); // in indicator + sheet
      expect(find.text('Deborde'), findsOneWidget);
      expect(find.text('Ferme'), findsOneWidget);
    });

    testWidgets('bottom sheet has 3 options when not auto_paused', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VendorStatusIndicator(
              status: VendorStatus.overwhelmed,
              interactive: true,
              onStatusChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Deborde'));
      await tester.pumpAndSettle();

      expect(find.text('Ouvert'), findsOneWidget);
      expect(find.text('Deborde'), findsWidgets);
      expect(find.text('Ferme'), findsOneWidget);
    });

    testWidgets('tapping option in bottom sheet calls onStatusChanged', (tester) async {
      VendorStatus? selectedStatus;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VendorStatusIndicator(
              status: VendorStatus.open,
              interactive: true,
              onStatusChanged: (s) => selectedStatus = s,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ouvert'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Deborde'));
      await tester.pumpAndSettle();

      expect(selectedStatus, VendorStatus.overwhelmed);
    });

    testWidgets('auto_paused shows reactivate button instead of options', (tester) async {
      VendorStatus? selectedStatus;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VendorStatusIndicator(
              status: VendorStatus.autoPaused,
              interactive: true,
              onStatusChanged: (s) => selectedStatus = s,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Auto-pause'));
      await tester.pumpAndSettle();

      expect(find.text('Vous etes en pause automatique'), findsOneWidget);
      expect(find.text('Reactiver'), findsOneWidget);
      expect(find.text('Changer mon statut'), findsNothing);

      await tester.tap(find.text('Reactiver'));
      await tester.pumpAndSettle();

      expect(selectedStatus, VendorStatus.open);
    });

    testWidgets('indicator has minimum 48dp touch target', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VendorStatusIndicator(
              status: VendorStatus.open,
              interactive: true,
              onStatusChanged: (_) {},
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.height, greaterThanOrEqualTo(48));
    });
  });

  // ─── Contraste WCAG AA (>= 4.5:1) ──────────────────────
  group('WCAG AA contrast', () {
    test('primary on white (light mode) >= 4.5:1', () {
      final ratio = _contrastRatio(MefaliColors.primaryLight, Colors.white);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('onSurface on surface (light mode) >= 4.5:1', () {
      final ratio = _contrastRatio(
        MefaliColors.onSurfaceLight,
        MefaliColors.surfaceLight,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('onSurface on surface (dark mode) >= 4.5:1', () {
      final ratio = _contrastRatio(
        MefaliColors.onSurfaceDark,
        MefaliColors.surfaceDark,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });
  });

  // ─── DeliveryMissionCard (UX-DR5) ──────────────────────
  group('DeliveryMissionCard', () {
    DeliveryMission createTestMission() => DeliveryMission(
          deliveryId: 'del-1',
          orderId: 'ord-1',
          merchantName: 'Maman Adjoua',
          merchantAddress: 'Marche central',
          deliveryAddress: 'Quartier Commerce',
          deliveryLat: 7.69,
          deliveryLng: -5.03,
          estimatedDistanceM: 800,
          deliveryFee: 35000,
          itemsSummary: 'Garba x1, Alloco x1',
          createdAt: '2026-03-20T12:00:00Z',
        );

    testWidgets('renders merchant name and delivery address', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: MefaliTheme.light(),
        home: Scaffold(
          body: DeliveryMissionCard(
            mission: createTestMission(),
            onAccept: () {},
          ),
        ),
      ));

      expect(find.text('Maman Adjoua'), findsOneWidget);
      expect(find.text('Quartier Commerce'), findsOneWidget);
      expect(find.text('Garba x1, Alloco x1'), findsOneWidget);
    });

    testWidgets('renders ACCEPTER button with minimum 56dp height',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: MefaliTheme.light(),
        home: Scaffold(
          body: DeliveryMissionCard(
            mission: createTestMission(),
            onAccept: () {},
          ),
        ),
      ));

      expect(find.text('ACCEPTER'), findsOneWidget);
      // Check the SizedBox wrapping the button
      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(FilledButton),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(sizedBox.height, 56);
    });

    testWidgets('calls onAccept when ACCEPTER tapped', (tester) async {
      var accepted = false;
      await tester.pumpWidget(MaterialApp(
        theme: MefaliTheme.light(),
        home: Scaffold(
          body: DeliveryMissionCard(
            mission: createTestMission(),
            onAccept: () => accepted = true,
          ),
        ),
      ));

      await tester.tap(find.text('ACCEPTER'));
      expect(accepted, isTrue);
    });

    testWidgets('shows countdown timer', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: MefaliTheme.light(),
        home: Scaffold(
          body: DeliveryMissionCard(
            mission: createTestMission(),
            onAccept: () {},
            autoDismissSeconds: 10,
          ),
        ),
      ));

      expect(find.text('10s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('8s'), findsOneWidget);
    });

    testWidgets('calls onDismiss after timeout', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(MaterialApp(
        theme: MefaliTheme.light(),
        home: Scaffold(
          body: DeliveryMissionCard(
            mission: createTestMission(),
            onAccept: () {},
            onDismiss: () => dismissed = true,
            autoDismissSeconds: 3,
          ),
        ),
      ));

      // Advance timer to just before timeout
      await tester.pump(const Duration(seconds: 2));
      expect(dismissed, isFalse);

      // Advance to timeout
      await tester.pump(const Duration(seconds: 1));
      expect(dismissed, isTrue);
    });

    testWidgets('displays gain in FCFA', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: MefaliTheme.light(),
        home: Scaffold(
          body: DeliveryMissionCard(
            mission: createTestMission(),
            onAccept: () {},
          ),
        ),
      ));

      // 35000 centimes = 350 FCFA
      expect(find.textContaining('350'), findsOneWidget);
    });

    testWidgets('shows distance when available', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: MefaliTheme.light(),
        home: Scaffold(
          body: DeliveryMissionCard(
            mission: createTestMission(),
            onAccept: () {},
          ),
        ),
      ));

      // 800m = ~0.8 km
      expect(find.text('~0.8 km'), findsOneWidget);
    });

    testWidgets('renders REFUSER button when onRefuse provided',
        (tester) async {
      var refused = false;
      await tester.pumpWidget(MaterialApp(
        theme: MefaliTheme.light(),
        home: Scaffold(
          body: DeliveryMissionCard(
            mission: createTestMission(),
            onAccept: () {},
            onRefuse: () => refused = true,
          ),
        ),
      ));

      expect(find.text('REFUSER'), findsOneWidget);
      await tester.tap(find.text('REFUSER'));
      expect(refused, isTrue);
    });

    testWidgets('does not render REFUSER button when onRefuse is null',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: MefaliTheme.light(),
        home: Scaffold(
          body: DeliveryMissionCard(
            mission: createTestMission(),
            onAccept: () {},
          ),
        ),
      ));

      expect(find.text('REFUSER'), findsNothing);
    });

    testWidgets('shows loading indicator when isLoading is true',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: MefaliTheme.light(),
        home: Scaffold(
          body: DeliveryMissionCard(
            mission: createTestMission(),
            onAccept: () {},
            isLoading: true,
          ),
        ),
      ));

      expect(find.text('ACCEPTER'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('disables buttons when isLoading is true', (tester) async {
      var accepted = false;
      var refused = false;
      await tester.pumpWidget(MaterialApp(
        theme: MefaliTheme.light(),
        home: Scaffold(
          body: DeliveryMissionCard(
            mission: createTestMission(),
            onAccept: () => accepted = true,
            onRefuse: () => refused = true,
            isLoading: true,
          ),
        ),
      ));

      // Tap the filled button (loading state)
      await tester.tap(find.byType(FilledButton));
      expect(accepted, isFalse);

      // Tap the outlined button (refuse)
      await tester.tap(find.byType(OutlinedButton));
      expect(refused, isFalse);
    });
  });
}
