import 'package:flutter/material.dart';

import '../core/extensions/context_ext.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_gradients.dart';
import '../core/theme/app_spacing.dart';

/// Pill switch with gradient track and soft glowing knob.
class PremiumSwitch extends StatelessWidget {
  const PremiumSwitch({super.key, required this.value, required this.onChanged, this.semanticLabel});
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: semanticLabel,
      child: GestureDetector(
        onTap: () {
          context.tapFeedback();
          onChanged(!value);
        },
        child: AnimatedContainer(
          duration: AppDurations.normal,
          curve: Curves.easeOutCubic,
          width: 54,
          height: 32,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: value ? AppGradients.primary : null,
            color: value ? null : AppColors.backgroundSecondary,
            border: Border.all(color: value ? Colors.transparent : AppColors.glassBorder),
          ),
          child: AnimatedAlign(
            duration: AppDurations.normal,
            curve: Curves.easeOutBack,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? Colors.white : AppColors.textMuted,
                boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 2))],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
