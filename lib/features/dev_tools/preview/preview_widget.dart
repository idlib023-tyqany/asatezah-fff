import 'package:flutter/material.dart';

import 'package:asatezah/main.dart' show RootScreen;

import '../dev_tools_model.dart';
import '../dev_tools_service.dart';
import './preview_view.dart';

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late final _items = DevToolsService().entries;

  void _openScreen(PreviewEntry item) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => item.builder()));
  }

  @override
  Widget build(BuildContext context) {
    return PreviewView(items: _items, onOpen: _openScreen, onNormalMode: _openNormalMode);
  }

  void _openNormalMode() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const RootScreen()));
  }
}
