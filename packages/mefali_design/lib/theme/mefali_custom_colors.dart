import 'package:flutter/material.dart';

import '../mefali_colors.dart';

/// Couleurs custom mefali non incluses dans [ColorScheme] M3.
///
/// Usage :
/// ```dart
/// final colors = Theme.of(context).extension<MefaliCustomColors>()!;
/// colors.success // vert confirmations
/// colors.warning // orange alertes temporaires
/// ```
@immutable
class MefaliCustomColors extends ThemeExtension<MefaliCustomColors> {
  const MefaliCustomColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
  });

  /// Preset light mode.
  static const light = MefaliCustomColors(
    success: MefaliColors.successLight,
    onSuccess: MefaliColors.onSuccessLight,
    successContainer: MefaliColors.successContainerLight,
    onSuccessContainer: MefaliColors.onSuccessContainerLight,
    warning: MefaliColors.warningLight,
  );

  /// Preset dark mode.
  static const dark = MefaliCustomColors(
    success: MefaliColors.successDark,
    onSuccess: MefaliColors.onSuccessDark,
    successContainer: MefaliColors.successContainerDark,
    onSuccessContainer: MefaliColors.onSuccessContainerDark,
    warning: MefaliColors.warningDark,
  );

  /// "+350 FCFA", confirmations, stock OK.
  final Color success;

  /// Texte sur fond [success].
  final Color onSuccess;

  /// Container success (fond clair).
  final Color successContainer;

  /// Texte sur [successContainer].
  final Color onSuccessContainer;

  /// SnackBar orange, etats "overwhelmed".
  final Color warning;

  @override
  MefaliCustomColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
  }) {
    return MefaliCustomColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
    );
  }

  @override
  MefaliCustomColors lerp(MefaliCustomColors? other, double t) {
    if (other is! MefaliCustomColors) return this;
    return MefaliCustomColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}
