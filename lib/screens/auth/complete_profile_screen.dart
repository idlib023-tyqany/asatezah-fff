import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/loading_button.dart';
import '../library/home_screen.dart'; // تأكد من صحة مسارHomeScreen هنا

// الثوابت الخاصة بالصفوف والمواد
const Map<String, List<String>> classesAndSubjects = {
  'الأول الابتدائي': ['معلم صف'],
  'الثاني الابتدائي': ['معلم صف'],
  'الثالث الابتدائي': ['معلم صف'],
  'الرابع الابتدائي': ['معلم صف'],
  'الخامس الابتدائي': ['رياضيات', 'علوم', 'لغة عربية', 'لغة إنجليزية'],
  'السادس الابتدائي': ['رياضيات', 'علوم', 'لغة عربية', 'لغة إنجليزية'],
  'التاسع': ['رياضيات', 'فيزياء وكيمياء', 'علم أحياء', 'لغة عربية'],
};

const List<String> primaryClasses = [
  'الأول الابتدائي',
  'الثاني الابتدائي',
  'الثالث الابتدائي',
  'الرابع الابتدائي',
];

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _fatherName = TextEditingController();
  final _familyName = TextEditingController();
  final _phoneNumber = TextEditingController();
  final _displayName = TextEditingController();

  bool _loading = false;
  String? _error;

  String? _trainerType;
  Set<String> selectedClasses = {};
  Map<String, Set<String>> selectedSubjects = {};

  @override
  void dispose() {
    _firstName.dispose();
    _fatherName.dispose();
    _familyName.dispose();
    _phoneNumber.dispose();
    _displayName.dispose();
    super.dispose();
  }

  // دالة حفظ البيانات وتحديث الملف الشخصي
  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_trainerType == null) {
      setState(() => _error = 'اختر نوع الحساب (معلم صف / مدرس)');
      return;
    }

    if (selectedClasses.isEmpty) {
      setState(() => _error = 'اختر صفاً واحداً على الأقل');
      return;
    }

    if (_trainerType == 'subject_teacher') {
      for (var className in selectedClasses) {
        if (!selectedSubjects.containsKey(className) || selectedSubjects[className]!.isEmpty) {
          setState(() => _error = 'اختر مادة واحدة على الأقل لكل صف');
          return;
        }
      }
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final fullName =
          '${_firstName.text.trim()} ${_fatherName.text.trim()} ${_familyName.text.trim()}'.trim();

      String specialization = '';
      if (_trainerType == 'class_teacher') {
        specialization = selectedClasses.join(', ');
      } else {
        final subjectsList = selectedSubjects.entries
            .expand((e) => e.value.map((subject) => '$subject للصف ${e.key}'))
            .toList();
        specialization = subjectsList.join(', ');
      }

      await AuthService().updateProfile(
        name: fullName,
        displayName: _displayName.text.trim(),
        phoneNumber: _phoneNumber.text.trim(),
        trainerType: _trainerType,
        specialization: specialization,
      );

      if (!mounted) return;
      Navigator.of(context)
          .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(
        () =>
            _error = error.statusCode == 422 ? 'تحقق من البيانات المدخلة' : 'تعذّر الاتصال بالخادم',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'تعذّر الاتصال بالخادم');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // دالة التخطي بالانتقال المباشر إلى الصفحة الرئيسية
  void _skipProfile() {
    Navigator.of(
      context,
    ).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إكمال البيانات'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'أكمل بيانات حسابك',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'يمكنك تجاوز هذه الخطوة والعودة إليها لاحقاً من ملفك الشخصي',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // الاسم الثلاثي
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstName,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'الاسم',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _fatherName,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'اسم الأب'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _familyName,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'الكنية'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // رقم الهاتف
                  TextFormField(
                    controller: _phoneNumber,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل رقم الهاتف' : null,
                  ),
                  const SizedBox(height: 16),

                  // الاسم الظاهر
                  TextFormField(
                    controller: _displayName,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'الاسم الظاهر (اللقب)',
                      prefixIcon: Icon(Icons.badge_outlined),
                      helperText: 'الاسم الذي تفضل أن تنادى به',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل الاسم الظاهر' : null,
                  ),
                  const SizedBox(height: 20),

                  // اختيار نوع الحساب
                  const Text(
                    'اختيار التخصص',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilterChip(
                          label: const Text('معلم صف'),
                          selected: _trainerType == 'class_teacher',
                          onSelected: (selected) {
                            setState(() {
                              _trainerType = selected ? 'class_teacher' : null;
                              selectedSubjects.clear();
                              selectedClasses.clear();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilterChip(
                          label: const Text('مدرس مواد'),
                          selected: _trainerType == 'subject_teacher',
                          onSelected: (selected) {
                            setState(() {
                              _trainerType = selected ? 'subject_teacher' : null;
                              selectedSubjects.clear();
                              selectedClasses.clear();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // الصفوف والمواد
                  if (_trainerType != null) ...[
                    Text(
                      _trainerType == 'class_teacher' ? 'الصف الذي تدرسه' : 'الصفوف والمواد',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    if (_trainerType == 'class_teacher')
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: classesAndSubjects.keys
                            .where((className) => primaryClasses.contains(className))
                            .map((className) {
                              final isSelected = selectedClasses.contains(className);
                              return FilterChip(
                                label: Text(className),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    selectedClasses.clear();
                                    if (selected) {
                                      selectedClasses.add(className);
                                    }
                                  });
                                },
                              );
                            })
                            .toList(),
                      )
                    else
                      ...classesAndSubjects.entries
                          .where((entry) => !primaryClasses.contains(entry.key))
                          .map((classEntry) {
                            final className = classEntry.key;
                            final subjects = classEntry.value;
                            final isClassSelected = selectedClasses.contains(className);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isClassSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey[300]!,
                                    width: isClassSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ExpansionTile(
                                  title: Text(
                                    className,
                                    style: TextStyle(
                                      fontWeight: isClassSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isClassSelected
                                          ? Theme.of(context).primaryColor
                                          : Colors.black,
                                    ),
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Wrap(
                                        spacing: 8.0,
                                        runSpacing: 8.0,
                                        children: subjects.map((subject) {
                                          final isSubjectSelected =
                                              selectedSubjects[className]?.contains(subject) ??
                                              false;

                                          return FilterChip(
                                            label: Text(subject),
                                            selected: isSubjectSelected,
                                            onSelected: (selected) {
                                              setState(() {
                                                selectedSubjects.putIfAbsent(className, () => {});

                                                if (selected) {
                                                  selectedSubjects[className]!.add(subject);
                                                  selectedClasses.add(className);
                                                } else {
                                                  selectedSubjects[className]!.remove(subject);
                                                  if (selectedSubjects[className]!.isEmpty) {
                                                    selectedClasses.remove(className);
                                                  }
                                                }
                                              });
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                  ],

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // زر الحفظ
                  LoadingButton(
                    loading: _loading,
                    onPressed: _completeProfile,
                    text: 'حفظ البيانات',
                  ),
                  const SizedBox(height: 8),

                  // زر التخطي المربوط بالدالة _skipProfile
                  OutlinedButton(onPressed: _skipProfile, child: const Text('تخطي الآن')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
