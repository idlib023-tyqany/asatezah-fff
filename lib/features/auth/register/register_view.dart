import 'package:flutter/material.dart';

import 'package:asatezah/core/widgets/loading_button.dart';

class RegisterView extends StatelessWidget {
  const RegisterView({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.passwordConfirmController,
    required this.isLoading,
    required this.isPasswordVisible,
    required this.isPasswordConfirmVisible,
    required this.errorMessage,
    required this.onRegister,
    required this.onPasswordVisibilityChanged,
    required this.onPasswordConfirmVisibilityChanged,
    required this.onGoogleSignUp,
    required this.onFacebookSignUp,
    required this.onLogin,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController passwordConfirmController;
  final bool isLoading;
  final bool isPasswordVisible;
  final bool isPasswordConfirmVisible;
  final String? errorMessage;
  final VoidCallback onRegister;
  final VoidCallback onPasswordVisibilityChanged;
  final VoidCallback onPasswordConfirmVisibilityChanged;
  final VoidCallback onGoogleSignUp;
  final VoidCallback onFacebookSignUp;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AutofillGroup(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'أنشئ حسابك الآن',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: Icon(Icons.email_outlined),
                        hintText: 'example@email.com',
                      ),
                      validator: (value) =>
                          (value == null ||
                              value.trim().isEmpty ||
                              !value.contains('@'))
                          ? 'أدخل بريداً صحيحاً'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: onPasswordVisibilityChanged,
                        ),
                      ),
                      validator: (value) => (value == null || value.length < 8)
                          ? 'كلمة المرور 8 أحرف على الأقل'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordConfirmController,
                      obscureText: !isPasswordConfirmVisible,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      onFieldSubmitted: (_) => onRegister(),
                      decoration: InputDecoration(
                        labelText: 'تأكيد كلمة المرور',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordConfirmVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: onPasswordConfirmVisibilityChanged,
                        ),
                      ),
                      validator: (value) => value != passwordController.text
                          ? 'كلمة المرور غير متطابقة'
                          : null,
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.error.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    LoadingButton(
                      loading: isLoading,
                      onPressed: onRegister,
                      text: 'إنشاء حساب',
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'أو',
                              style: TextStyle(color: theme.hintColor),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: isLoading ? null : onGoogleSignUp,
                      icon: const Icon(Icons.g_mobiledata_rounded),
                      label: const Text('التسجيل بحساب جوجل'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: isLoading ? null : onFacebookSignUp,
                      icon: const Icon(Icons.facebook_rounded),
                      label: const Text('التسجيل بحساب فيسبوك'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: isLoading ? null : onLogin,
                      child: const Text('لديّ حساب بالفعل'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
