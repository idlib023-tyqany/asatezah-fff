import 'package:flutter/material.dart';

class AdminUsersView extends StatelessWidget {
  const AdminUsersView({
    required this.users,
    required this.filteredUsers,
    required this.selectedIds,
    required this.selectedRoleFilter,
    required this.searchController,
    required this.isLoading,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onClearSearch,
    required this.onRefresh,
    required this.onRoleFilterChanged,
    required this.onSelectAllFiltered,
    required this.onSelectionChanged,
    required this.onToggleContribution,
    required this.onDeleteUser,
    required this.onApplyToSelected,
    super.key,
  });

  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> filteredUsers;
  final Set<int> selectedIds;
  final String selectedRoleFilter;
  final TextEditingController searchController;
  final bool isLoading;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onClearSearch;
  final VoidCallback onRefresh;
  final ValueChanged<String> onRoleFilterChanged;
  final VoidCallback onSelectAllFiltered;
  final void Function(int id, bool selected) onSelectionChanged;
  final ValueChanged<Map<String, dynamic>> onToggleContribution;
  final ValueChanged<Map<String, dynamic>> onDeleteUser;
  final void Function({required bool delete}) onApplyToSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchText = searchController.text;
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedIds.isEmpty ? 'إدارة المستخدمين' : '${selectedIds.length} محدد'),
        actions: [
          if (selectedIds.isNotEmpty) ...[
            IconButton(
              onPressed: () => onApplyToSelected(delete: false),
              icon: const Icon(Icons.block),
              tooltip: 'حظر المحددين',
            ),
            IconButton(
              onPressed: () => onApplyToSelected(delete: true),
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'حذف المحددين',
            ),
          ],
          if (filteredUsers.isNotEmpty)
            IconButton(
              icon: Icon(selectedIds.isEmpty ? Icons.select_all : Icons.deselect),
              tooltip: selectedIds.isEmpty ? 'تحديد الكل' : 'إلغاء التحديد',
              onPressed: onSelectAllFiltered,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    textInputAction: TextInputAction.search,
                    onSubmitted: onSearchSubmitted,
                    decoration: InputDecoration(
                      hintText: 'ابحث بالاسم، البريد، الهاتف أو التخصص...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchText.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.clear), onPressed: onClearSearch)
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'تحديث',
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                _filterChip('all', 'الكل (${users.length})'),
                _filterChip('admin', 'المشرفين'),
                _filterChip('contributor', 'المساهمين'),
                _filterChip('blocked', 'المحظورين'),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          searchText.isNotEmpty ? 'لا توجد نتائج مطابقة للبحث' : 'لا يوجد مستخدمون',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredUsers.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, indent: 68),
                    itemBuilder: (context, index) =>
                        _userTile(context, theme, filteredUsers[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String role, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: FilterChip(
        selected: selectedRoleFilter == role,
        label: Text(label),
        onSelected: (_) => onRoleFilterChanged(role),
      ),
    );
  }

  Widget _userTile(BuildContext context, ThemeData theme, Map<String, dynamic> user) {
    final id = user['id'] as int;
    final canContribute = user['can_contribute'] ?? true;
    final isAdmin = user['role'] == 'admin';
    final isSelected = selectedIds.contains(id);
    return ListTile(
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
      onTap: () => _showDetails(context, user),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isAdmin)
            Checkbox(
              value: isSelected,
              onChanged: (selected) => onSelectionChanged(id, selected == true),
            )
          else
            const SizedBox(width: 48),
          CircleAvatar(
            backgroundColor: isAdmin
                ? Colors.amber.shade700
                : (canContribute ? theme.colorScheme.primary : Colors.grey),
            child: Text(
              (user['name'] ?? '?').toString()[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              user['name']?.toString() ?? 'مستخدم',
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'إداري',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.amber.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        [
          user['email'] ?? '',
          if (!isAdmin) (canContribute ? 'مساهم' : 'محظور من المساهمة'),
          if (user['specialization'] != null) user['specialization'],
        ].where((value) => value.toString().isNotEmpty).join(' • '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey[700]),
      ),
      trailing: !isAdmin
          ? PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'toggle') onToggleContribution(user);
                if (value == 'delete') onDeleteUser(user);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        canContribute ? Icons.block : Icons.check_circle,
                        color: canContribute ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(canContribute ? 'حظر المساهمة' : 'السماح بالمساهمة'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Text('حذف الحساب', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            )
          : null,
    );
  }

  void _showDetails(BuildContext context, Map<String, dynamic> user) {
    final theme = Theme.of(context);
    final canContribute = user['can_contribute'] ?? true;
    final isAdmin = user['role'] == 'admin';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            Center(
              child: CircleAvatar(
                radius: 36,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  (user['name'] ?? '?').toString()[0].toUpperCase(),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user['name']?.toString() ?? 'مستخدم مجهول',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              user['email']?.toString() ?? '',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            _infoTile(Icons.perm_identity, 'المعرف الرقمي', user['id'].toString()),
            _infoTile(Icons.phone_outlined, 'رقم الهاتف', user['phone']?.toString() ?? 'غير محدد'),
            _infoTile(
              Icons.school_outlined,
              'التخصص',
              user['specialization']?.toString() ?? 'غير محدد',
            ),
            _infoTile(Icons.security, 'نوع الحساب', isAdmin ? 'إداري (Admin)' : 'مستخدم عادي'),
            _infoTile(
              Icons.stars_outlined,
              'حالة المساهمة',
              isAdmin ? 'متاح دائماً' : (canContribute ? 'مسموح بالمساهمة' : 'محظور من المساهمة'),
            ),
            _infoTile(
              Icons.calendar_today_outlined,
              'تاريخ الانضمام',
              user['created_at']?.toString() ?? 'غير معروف',
            ),
            const SizedBox(height: 24),
            if (!isAdmin) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onToggleContribution(user);
                      },
                      icon: Icon(canContribute ? Icons.block : Icons.check_circle),
                      label: Text(canContribute ? 'حظر المساهمة' : 'السماح بالمساهمة'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        Navigator.pop(context);
                        onDeleteUser(user);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('حذف الحساب'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(value, style: TextStyle(color: Colors.grey[800])),
        ],
      ),
    );
  }
}
