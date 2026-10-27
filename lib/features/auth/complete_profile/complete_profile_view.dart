import 'package:flutter/material.dart';

import 'package:asatezah/features/auth/login/login_model.dart';
import 'package:asatezah/core/widgets/loading_button.dart';

class CompleteProfileView extends StatelessWidget {
  const CompleteProfileView({
    required this.formKey,
    required this.firstNameController,
    required this.fatherNameController,
    required this.familyNameController,
    required this.phoneNumberController,
    required this.displayNameController,
    required this.grades,
    required this.selectedGrade,
    required this.selectedSubject,
    required this.trainerType,
    required this.isLoading,
    required this.isFetchingData,
    required this.errorMessage,
    required this.onTrainerTypeSelected,
    required this.onGradeSelected,
    required this.onSubjectSelected,
    required this.onSubmit,
    required this.onSkip,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController fatherNameController;
  final TextEditingController familyNameController;
  final TextEditingController phoneNumberController;
  final TextEditingController displayNameController;
  final List<GradeModel> grades;
  final GradeModel? selectedGrade;
  final SubjectModel? selectedSubject;
  final String? trainerType;
  final bool isLoading;
  final bool isFetchingData;
  final String? errorMessage;
  final ValueChanged<String?> onTrainerTypeSelected;
  final ValueChanged<GradeModel?> onGradeSelected;
  final ValueChanged<SubjectModel?> onSubjectSelected;
  final VoidCallback onSubmit;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('إكمال البيانات'), centerTitle: true),
      body: isFetchingData
          ? const Center(child: CircularProgressIndicator())
          : Center(
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
                          const Text(
                            'أكمل بيانات حسابك',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'يمكنك تجاوز هذه الخطوة والعودة إليها لاحقاً من ملفك الشخصي',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: theme.hintColor),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: firstNameController,
                                  autofillHints: const [AutofillHints.givenName],
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(labelText: 'الاسم'),
                                  validator: _requiredValidator,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: fatherNameController,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(labelText: 'اسم الأب'),
                                  validator: _requiredValidator,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: familyNameController,
                                  autofillHints: const [AutofillHints.familyName],
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(labelText: 'الكنية'),
                                  validator: _requiredValidator,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: phoneNumberController,
                            autofillHints: const [AutofillHints.telephoneNumber],
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'رقم الهاتف',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty) ? 'أدخل رقم الهاتف' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: displayNameController,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'الاسم الظاهر (اللقب)',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty) ? 'أدخل الاسم الظاهر' : null,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'نوع التخصص',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilterChip(
                                  label: const Text('معلم صف'),
                                  selected: trainerType == 'class_teacher',
                                  onSelected: (selected) =>
                                      onTrainerTypeSelected(selected ? 'class_teacher' : null),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilterChip(
                                  label: const Text('مدرس مادة'),
                                  selected: trainerType == 'subject_teacher',
                                  onSelected: (selected) =>
                                      onTrainerTypeSelected(selected ? 'subject_teacher' : null),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (trainerType != null) ...[
                            DropdownButtonFormField<GradeModel>(
                              initialValue: selectedGrade,
                              decoration: const InputDecoration(
                                labelText: 'اختر الصف الدراسي',
                                prefixIcon: Icon(Icons.school_outlined),
                                border: OutlineInputBorder(),
                              ),
                              items: grades
                                  .map(
                                    (grade) => DropdownMenuItem(
                                      value: grade,
                                      child: Text(grade.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: onGradeSelected,
                              validator: (value) => value == null ? 'يرجى اختيار الصف' : null,
                            ),
                            const SizedBox(height: 16),
                            if (trainerType == 'subject_teacher' && selectedGrade != null) ...[
                              DropdownButtonFormField<SubjectModel>(
                                initialValue: selectedSubject,
                                decoration: const InputDecoration(
                                  labelText: 'اختر المادة الدراسية',
                                  prefixIcon: Icon(Icons.book_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                items: selectedGrade!.subjects
                                    .map(
                                      (subject) => DropdownMenuItem(
                                        value: subject,
                                        child: Text(subject.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: onSubjectSelected,
                                validator: (value) => value == null ? 'يرجى اختيار المادة' : null,
                              ),
                              const SizedBox(height: 16),
                            ],
                          ],
                          if (errorMessage != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
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
                            onPressed: onSubmit,
                            text: 'حفظ البيانات',
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(onPressed: onSkip, child: const Text('تخطي الآن')),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  String? _requiredValidator(String? value) =>
      (value == null || value.trim().isEmpty) ? 'مطلوب' : null;
}
