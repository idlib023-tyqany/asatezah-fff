import 'package:flutter/material.dart';

/// LoadingButton: زر تفاعلي موحد يدعم حالة التحميل وألوان الثيم المخصصة
class LoadingButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;
  final String text;
  final Widget? icon;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry padding;

  const LoadingButton({
    super.key,
    required this.loading,
    required this.onPressed,
    required this.text,
    this.icon,
    this.width,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    this.padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null && !loading;

    // لون المؤشر والنص يتكيف مع لون النص الرئيسي المخصص للزر
    final effectiveForegroundColor =
        foregroundColor ??
        (backgroundColor != null
            ? _getContrastingColor(backgroundColor!)
            : theme.colorScheme.onPrimary);

    final buttonChild = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: loading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(effectiveForegroundColor),
              ),
            )
          : Row(
              key: const ValueKey('content'),
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[icon!, const SizedBox(width: 8)],
                Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
    );

    return SizedBox(
      width: width,
      height: height,
      child: FilledButton(
        onPressed: isEnabled ? onPressed : null,
        style: FilledButton.styleFrom(
          padding: padding,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: loading ? backgroundColor?.withValues(alpha: 0.7) : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: buttonChild,
      ),
    );
  }

  /// حاسبة بسيطة لاختيار لون متجانس للمؤشر إن تم تحديد لون خلفية مخصص
  Color _getContrastingColor(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
  }
}
