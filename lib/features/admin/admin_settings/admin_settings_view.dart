import 'dart:typed_data';

import 'package:flutter/material.dart';

class AdminSettingsView extends StatelessWidget {
  const AdminSettingsView({
    required this.formKey,
    required this.appNameController,
    required this.appVersionController,
    required this.facebookController,
    required this.instagramController,
    required this.twitterController,
    required this.logoBytes,
    required this.isLoading,
    required this.isSaving,
    required this.isUploadingLogo,
    required this.onRefresh,
    required this.onUploadLogo,
    required this.onSave,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController appNameController;
  final TextEditingController appVersionController;
  final TextEditingController facebookController;
  final TextEditingController instagramController;
  final TextEditingController twitterController;
  final Uint8List? logoBytes;
  final bool isLoading;
  final bool isSaving;
  final bool isUploadingLogo;
  final Future<void> Function() onRefresh;
  final VoidCallback onUploadLogo;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات التطبيق'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (isLoading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _logoSection(context),
                          const SizedBox(height: 24),
                          _sectionTitle(context, 'البيانات الأساسية'),
                          const SizedBox(height: 12),
                          _textField(
                            controller: appNameController,
                            label: 'اسم التطبيق',
                            icon: Icons.apps,
                            validator: (value) =>
                                value == null || value.isEmpty ? 'هذا الحقل مطلوب' : null,
                          ),
                          const SizedBox(height: 16),
                          _textField(
                            controller: appVersionController,
                            label: 'إصدار التطبيق',
                            icon: Icons.verified_outlined,
                            validator: (value) =>
                                value == null || value.isEmpty ? 'هذا الحقل مطلوب' : null,
                          ),
                          const SizedBox(height: 24),
                          _sectionTitle(context, 'وسائل التواصل الاجتماعي'),
                          const SizedBox(height: 12),
                          _textField(
                            controller: facebookController,
                            label: 'رابط فيسبوك',
                            icon: Icons.facebook,
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 16),
                          _textField(
                            controller: instagramController,
                            label: 'رابط إنستغرام',
                            icon: Icons.camera_alt_outlined,
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 16),
                          _textField(
                            controller: twitterController,
                            label: 'رابط منصة X (تويتر)',
                            icon: Icons.alternate_email,
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 32),
                          _submitButton(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _logoSection(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
              image: logoBytes == null
                  ? null
                  : DecorationImage(image: MemoryImage(logoBytes!), fit: BoxFit.cover),
            ),
            child: logoBytes == null ? const Icon(Icons.image, size: 50, color: Colors.grey) : null,
          ),
          if (isUploadingLogo)
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black38),
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                onPressed: isUploadingLogo ? null : onUploadLogo,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _submitButton() {
    return ElevatedButton(
      onPressed: isSaving ? null : onSave,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isSaving
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : const Text(
              'حفظ التغييرات',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }
}
