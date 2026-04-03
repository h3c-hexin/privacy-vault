import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:privacy_vault/core/theme/app_colors.dart';
import 'package:privacy_vault/core/theme/app_spacing.dart';

/// PIN 码圆点显示（带输入动画）
class PinInput extends StatelessWidget {
  final String pin;
  final int maxLength;

  const PinInput({
    super.key,
    required this.pin,
    this.maxLength = 6,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxLength, (index) {
        final isFilled = index < pin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          width: isFilled ? 18 : 16,
          height: isFilled ? 18 : 16,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? cs.primary : Colors.transparent,
            border: Border.all(
              color: isFilled ? cs.primary : cs.outline,
              width: 2,
            ),
          ),
        );
      }),
    );
  }
}

/// 数字键盘
class PinKeyboard extends StatelessWidget {
  final void Function(String key) onKeyPressed;

  const PinKeyboard({super.key, required this.onKeyPressed});

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'delete'],
    ];

    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: row.map((key) {
            if (key.isEmpty) {
              return const SizedBox(width: 80, height: 64);
            }
            return _KeyButton(
              label: key,
              onPressed: () => onKeyPressed(key),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _KeyButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDelete = label == 'delete';

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      borderRadius: BorderRadius.circular(40),
      child: SizedBox(
        width: 80,
        height: 64,
        child: Center(
          child: isDelete
              ? Icon(
                  Icons.backspace_outlined,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 24,
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
        ),
      ),
    );
  }
}
