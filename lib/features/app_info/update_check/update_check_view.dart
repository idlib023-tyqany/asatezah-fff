import 'package:flutter/material.dart';

import 'package:asatezah/core/widgets/app_logo.dart';

class UpdateCheckView extends StatelessWidget {
  const UpdateCheckView({
    required this.isLoading,
    required this.errorMessage,
    required this.onContinue,
    required this.onRetry,
    super.key,
  });

  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onContinue;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo(size: 90),
              const SizedBox(height: 24),
              if (isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'جاري التحقق من التحديثات...',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ] else if (errorMessage != null) ...[
                Icon(Icons.wifi_off_rounded, size: 48, color: Colors.amber.shade800),
                const SizedBox(height: 12),
                Text(errorMessage!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(onPressed: onContinue, child: const Text('المتابعة للتطبيق')),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
