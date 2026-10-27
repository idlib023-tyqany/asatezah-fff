import 'package:flutter/material.dart';

import 'package:asatezah/core/network/api_service.dart';
import 'package:asatezah/features/auth/login/login_model.dart';
import 'package:asatezah/features/auth/auth_service.dart';
import 'package:asatezah/features/library/home/home_screen.dart';

import './complete_profile_view.dart';

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
  bool _fetchingData = true; // حالة تحميل البيانات من السيرفر
  String? _error;

  String? _trainerType; // 'class_teacher' أو 'subject_teacher'

  // قائمة الصفوف المجلوبة من السيرفر
  List<GradeModel> _grades = [];

  // العناصر المحددة من المنسدلات (Select Options)
  GradeModel? _selectedGrade;
  SubjectModel? _selectedSubject;

  @override
  void initState() {
    super.initState();
    _fetchGradesAndSubjects();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _fatherName.dispose();
    _familyName.dispose();
    _phoneNumber.dispose();
    _displayName.dispose();
    super.dispose();
  }

  // 1. جلب الصفوف والمواد من الداشبورد عبر الـ API
  Future<void> _fetchGradesAndSubjects() async {
    try {
      // محاكاة جلب بيانات للتوضيح
      await Future.delayed(const Duration(milliseconds: 800));
      final List<Map<String, dynamic>> mockData = [
        {
          "id": 1,
          "name": "الأول الابتدائي",
          "subjects": [
            {"id": 101, "name": "معلم صف"},
          ],
        },
        {
          "id": 2,
          "name": "التاسع",
          "subjects": [
            {"id": 201, "name": "رياضيات"},
            {"id": 202, "name": "فيزياء وكيمياء"},
            {"id": 203, "name": "علم أحياء"},
          ],
        },
      ];

      if (!mounted) return;
      setState(() {
        _grades = mockData.map((e) => GradeModel.fromJson(e)).toList();
        _fetchingData = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر تحميل قائمة الصفوف والمواد';
        _fetchingData = false;
      });
    }
  }

  // 2. إرسال بيانات الملف الشخصي
  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_trainerType == null) {
      setState(() => _error = 'اختر نوع الحساب');
      return;
    }

    if (_selectedGrade == null) {
      setState(() => _error = 'يرجى اختيار الصف الدراسي');
      return;
    }

    if (_trainerType == 'subject_teacher' && _selectedSubject == null) {
      setState(() => _error = 'يرجى اختيار المادة الدراسية');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final fullName =
          '${_firstName.text.trim()} ${_fatherName.text.trim()} ${_familyName.text.trim()}'.trim();

      // تجهيز التخصص بناءً على المدخلات
      String specialization = '';
      if (_trainerType == 'class_teacher') {
        specialization = 'معلم صف - ${_selectedGrade!.name}';
      } else {
        // تم تصحيح الخطأ هنا
        specialization = '${_selectedSubject!.name} - ${_selectedGrade!.name}';
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

  void _skipProfile() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
  }

  void _selectTrainerType(String? trainerType) {
    setState(() {
      _trainerType = trainerType;
      _selectedGrade = null;
      _selectedSubject = null;
    });
  }

  void _selectGrade(GradeModel? grade) {
    setState(() {
      _selectedGrade = grade;
      _selectedSubject = null;
    });
  }

  void _selectSubject(SubjectModel? subject) {
    setState(() => _selectedSubject = subject);
  }

  @override
  Widget build(BuildContext context) {
    return CompleteProfileView(
      formKey: _formKey,
      firstNameController: _firstName,
      fatherNameController: _fatherName,
      familyNameController: _familyName,
      phoneNumberController: _phoneNumber,
      displayNameController: _displayName,
      grades: _grades,
      selectedGrade: _selectedGrade,
      selectedSubject: _selectedSubject,
      trainerType: _trainerType,
      isLoading: _loading,
      isFetchingData: _fetchingData,
      errorMessage: _error,
      onTrainerTypeSelected: _selectTrainerType,
      onGradeSelected: _selectGrade,
      onSubjectSelected: _selectSubject,
      onSubmit: _completeProfile,
      onSkip: _skipProfile,
    );
  }
}
