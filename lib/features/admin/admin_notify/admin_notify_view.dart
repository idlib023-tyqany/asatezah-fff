import 'package:flutter/material.dart';

import 'package:asatezah/features/resource_hub/resource_hub/resource_hub_model.dart';

class AdminNotifyView extends StatelessWidget {
  const AdminNotifyView({
    required this.titleController,
    required this.bodyController,
    required this.categories,
    required this.selectedCategoryIds,
    required this.toAll,
    required this.isLoadingCategories,
    required this.isSending,
    required this.onAudienceChanged,
    required this.onToggleSelectAll,
    required this.onToggleCategory,
    required this.onSend,
    super.key,
  });

  final TextEditingController titleController;
  final TextEditingController bodyController;
  final List<CatalogItem> categories;
  final Set<int> selectedCategoryIds;
  final bool toAll;
  final bool isLoadingCategories;
  final bool isSending;
  final ValueChanged<bool> onAudienceChanged;
  final ValueChanged<bool> onToggleSelectAll;
  final void Function(int id, bool selected) onToggleCategory;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final allSelected =
        categories.isNotEmpty && selectedCategoryIds.length == categories.length;

    return Scaffold(
      appBar: AppBar(title: const Text('إرسال إشعار')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('لجميع المستخدمين'),
                icon: Icon(Icons.people_alt_outlined),
              ),
              ButtonSegment(
                value: false,
                label: Text('حسب التخصص'),
                icon: Icon(Icons.category_outlined),
              ),
            ],
            selected: {toAll},
            onSelectionChanged: (selection) => onAudienceChanged(selection.first),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'عنوان الإشعار',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: bodyController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'نص الإشعار',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          if (!toAll) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'اختر التخصصات والصفوف المستهدفة:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (categories.isNotEmpty)
                  TextButton(
                    onPressed: () => onToggleSelectAll(!allSelected),
                    child: Text(allSelected ? 'إلغاء تحديد الكل' : 'تحديد الكل'),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (isLoadingCategories)
              const Center(child: CircularProgressIndicator())
            else if (categories.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('لا توجد تخصصات مضافة بعد.', style: TextStyle(color: Colors.grey)),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((item) {
                  return FilterChip(
                    label: Text(item.name),
                    selected: selectedCategoryIds.contains(item.id),
                    onSelected: (selected) => onToggleCategory(item.id, selected),
                  );
                }).toList(),
              ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: isSending ? null : onSend,
              icon: isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(isSending ? 'جاري الإرسال...' : 'إرسال الإشعار'),
            ),
          ),
        ],
      ),
    );
  }
}
