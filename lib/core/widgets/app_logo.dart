import 'package:flutter/material.dart';

/// AppLogo: مكون عرض شعار التطبيق الموحد مع خيارات العرض المتقدمة
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 72,
    this.fit = BoxFit.contain,
    this.showText = false,
    this.text,
    this.textStyle,
    this.textColor,
    this.color,
    this.colorBlendMode,
    this.borderRadius,
    this.spacing = 8.0,
  });

  /// حجم الشعار (العرض والارتفاع)
  final double size;

  /// طريقة ملاءمة الصورة داخل أبعادها
  final BoxFit fit;

  /// إظهار اسم التطبيق أسفل الشعار
  final bool showText;

  /// النص البديل للشعار (إذا لم يُحدد سيعرض 'أساتذة')
  final String? text;

  /// نمط النص مخصص
  final TextStyle? textStyle;

  /// لون النص المخصص
  final Color? textColor;

  /// تطبيق لون معين على الشعار (Icon / Tint)
  final Color? color;

  /// نمط دمج اللون مع الصورة
  final BlendMode? colorBlendMode;

  /// حواف دائرية للصورة
  final BorderRadius? borderRadius;

  /// التباعد بين الصورة والنص
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget imageWidget = Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: fit,
      color: color,
      colorBlendMode: colorBlendMode,
      semanticLabel: text ?? 'شعار أساتذة',
      errorBuilder: (context, error, stackTrace) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        child: Icon(
          Icons.school_outlined,
          size: size * 0.8,
          color: color ?? theme.colorScheme.primary,
        ),
      ),
    );

    // تطبيق الحواف الدائرية إن وُجدت
    if (borderRadius != null) {
      imageWidget = ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    if (!showText) return imageWidget;

    // دمج التنسيق الافتراضي مع التنسيقات والألوان المُمَرّرة
    final defaultStyle =
        theme.textTheme.titleMedium?.merge(const TextStyle(fontWeight: FontWeight.bold)) ??
        const TextStyle(fontWeight: FontWeight.bold);

    final effectiveStyle = defaultStyle.copyWith(color: textColor).merge(textStyle);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        imageWidget,
        SizedBox(height: spacing),
        Text(text ?? 'أساتذة', style: effectiveStyle, textAlign: TextAlign.center),
      ],
    );
  }
}
