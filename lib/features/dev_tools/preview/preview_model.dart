import 'package:flutter/material.dart';

class PreviewEntry {
  const PreviewEntry(this.title, this.group, this.icon, this.builder);

  final String title;
  final String group;
  final IconData icon;
  final Widget Function() builder;
}
