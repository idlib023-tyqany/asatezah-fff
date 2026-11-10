import 'package:flutter/material.dart';

enum TeacherAiMode {
  lessonPlan('lesson_plan', 'خطة درس', Icons.edit_note),
  exam('exam', 'بنك أسئلة وامتحان', Icons.quiz_outlined),
  gradingScale('grading_scale', 'حاسبة سلم الدرجات', Icons.calculate_outlined),
  homework('homework', 'واجب منزلي متوازن', Icons.assignment_outlined),
  solve('solve', 'حل مسائل وتمارين', Icons.functions_rounded),
  simplify('simplify', 'تبسيط وتجارب بديلة', Icons.lightbulb_outline),
  formulaSheet(
    'formula_sheet',
    'بطاقة قوانين سريعة',
    Icons.view_headline_rounded,
  );

  const TeacherAiMode(this.key, this.label, this.icon);

  final String key;
  final String label;
  final IconData icon;
}

class TeacherAiMessage {
  const TeacherAiMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}
