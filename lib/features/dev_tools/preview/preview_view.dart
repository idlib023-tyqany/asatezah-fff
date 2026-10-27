import 'package:flutter/material.dart';

import 'package:asatezah/core/widgets/app_logo.dart';
import 'package:asatezah/features/dev_tools/dev_tools_model.dart';

class PreviewView extends StatefulWidget {
  const PreviewView({
    super.key,
    required this.items,
    required this.onOpen,
    required this.onNormalMode,
  });

  final List<PreviewEntry> items;
  final ValueChanged<PreviewEntry> onOpen;
  final VoidCallback onNormalMode;

  @override
  State<PreviewView> createState() => _PreviewViewState();
}

class _PreviewViewState extends State<PreviewView> {
  PreviewEntry? _selected;
  String _searchQuery = '';
  String _selectedGroup = 'الكل';

  List<String> get _groups => ['الكل', ...widget.items.map((item) => item.group).toSet()];

  List<PreviewEntry> get _filteredItems {
    final query = _searchQuery.toLowerCase();
    return widget.items.where((item) {
      final matchesGroup = _selectedGroup == 'الكل' || item.group == _selectedGroup;
      final matchesSearch =
          query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.group.toLowerCase().contains(query);
      return matchesGroup && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('معاينة الواجهات'),
        actions: [
          TextButton.icon(
            onPressed: widget.onNormalMode,
            icon: const Icon(Icons.play_arrow),
            label: const Text('الوضع الطبيعي'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  const AppLogo(size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'أساتذة',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (value) => setState(() => _searchQuery = value.trim()),
                    decoration: InputDecoration(
                      hintText: 'بحث في الواجهات...',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _groups.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final group = _groups[index];
                  return ChoiceChip(
                    label: Text(group),
                    selected: group == _selectedGroup,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedGroup = group);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('لا توجد واجهات تطابق البحث'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 180,
                        mainAxisExtent: 128,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final selected = item == _selected;
                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => setState(() => _selected = item),
                          onDoubleTap: () {
                            setState(() => _selected = item);
                            widget.onOpen(item);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: selected
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outlineVariant,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    item.icon,
                                    color: selected
                                        ? theme.colorScheme.onPrimaryContainer
                                        : theme.colorScheme.primary,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item.title,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: selected ? theme.colorScheme.onPrimaryContainer : null,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.group,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (_selected != null)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => widget.onOpen(_selected!),
                      icon: const Icon(Icons.open_in_new),
                      label: Text('فتح الواجهة: ${_selected!.title}'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
