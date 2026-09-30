import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/admin_service.dart';

class AdminUsers extends StatefulWidget {
  const AdminUsers({super.key});

  @override
  State<AdminUsers> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<AdminUsers> {
  final _admin = AdminService();
  final _search = TextEditingController();
  Timer? _debounce;

  List<dynamic> _users = [];
  final Set<int> _selectedIds = {};
  bool _loading = true;
  String _selectedRoleFilter = 'all'; // all, admin, contributor, blocked

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _load();
    });
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final result = await _admin.fetchUsers(q: _search.text.trim());
      if (!mounted) return;
      setState(() {
        _users = result['data'] as List<dynamic>? ?? [];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> get _filteredUsers {
    if (_selectedRoleFilter == 'admin') {
      return _users.where((u) => u['role'] == 'admin').toList();
    } else if (_selectedRoleFilter == 'contributor') {
      return _users.where((u) => u['role'] != 'admin' && (u['can_contribute'] ?? true)).toList();
    } else if (_selectedRoleFilter == 'blocked') {
      return _users.where((u) => u['role'] != 'admin' && !(u['can_contribute'] ?? true)).toList();
    }
    return _users;
  }

  Future<void> _toggleContribution(Map<String, dynamic> user) async {
    final can = user['can_contribute'] ?? true;
    try {
      await _admin.setContribution(user['id'], !can);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(!can ? 'تم التمكين من المساهمة' : 'تم حظر المستخدم من المساهمة')),
      );
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تعذّر تغيير حالة المساهمة')));
      }
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت تأكد من حذف المستخدم "${user['name'] ?? 'المحدد'}" نهائياً؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _admin.deleteUser(user['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم حذف المستخدم بنجاح')));
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('لا يمكن حذف المستخدم المختار')));
      }
    }
  }

  Future<void> _applyToSelected({required bool delete}) async {
    final selected = _users
        .where((user) => _selectedIds.contains(user['id']) && user['role'] != 'admin')
        .toList();
    if (selected.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(delete ? 'حذف المحددين' : 'حظر المحددين'),
        content: Text(
          delete
              ? 'هل تريد حذف ${selected.length} مستخدم نهائياً؟'
              : 'هل تريد حظر ${selected.length} مستخدم من المساهمة؟',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            style: delete ? FilledButton.styleFrom(backgroundColor: Colors.red) : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      for (final user in selected) {
        if (delete) {
          await _admin.deleteUser(user['id']);
        } else {
          await _admin.setContribution(user['id'], false);
        }
      }
      setState(() => _selectedIds.clear());
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تعذّر تطبيق الإجراء على بعض المستخدمين')));
      }
    }
  }

  void _selectAllFiltered() {
    setState(() {
      final selectable = _filteredUsers
          .where((u) => u['role'] != 'admin')
          .map((u) => u['id'] as int);
      if (_selectedIds.containsAll(selectable)) {
        _selectedIds.removeAll(selectable);
      } else {
        _selectedIds.addAll(selectable);
      }
    });
  }

  void _showUserDetails(Map<String, dynamic> user) {
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
              user['name'] ?? 'مستخدم مجهول',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              user['email'] ?? '',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            _infoTile(Icons.perm_identity, 'المعرف الرقمي', user['id'].toString()),
            _infoTile(Icons.phone_outlined, 'رقم الهاتف', user['phone'] ?? 'غير محدد'),
            _infoTile(Icons.school_outlined, 'التخصص', user['specialization'] ?? 'غير محدد'),
            _infoTile(Icons.security, 'نوع الحساب', isAdmin ? 'إداري (Admin)' : 'مستخدم عادي'),
            _infoTile(
              Icons.stars_outlined,
              'حالة المساهمة',
              isAdmin ? 'متاح دائماً' : (canContribute ? 'مسموح بالمساهمة' : 'محظور من المساهمة'),
            ),
            _infoTile(
              Icons.calendar_today_outlined,
              'تاريخ الانضمام',
              user['created_at'] ?? 'غير معروف',
            ),
            const SizedBox(height: 24),
            if (!isAdmin) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _toggleContribution(user);
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
                        _deleteUser(user);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayedList = _filteredUsers;

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIds.isEmpty ? 'إدارة المستخدمين' : '${_selectedIds.length} محدد'),
        actions: [
          if (_selectedIds.isNotEmpty) ...[
            IconButton(
              onPressed: () => _applyToSelected(delete: false),
              icon: const Icon(Icons.block),
              tooltip: 'حظر المحددين',
            ),
            IconButton(
              onPressed: () => _applyToSelected(delete: true),
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'حذف المحددين',
            ),
          ],
          if (displayedList.isNotEmpty)
            IconButton(
              icon: Icon(_selectedIds.isEmpty ? Icons.select_all : Icons.deselect),
              tooltip: _selectedIds.isEmpty ? 'تحديد الكل' : 'إلغاء التحديد',
              onPressed: _selectAllFiltered,
            ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _load(),
                    decoration: InputDecoration(
                      hintText: 'ابحث بالاسم، البريد، الهاتف أو التخصص...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _search.clear();
                                _load();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'تحديث',
                ),
              ],
            ),
          ),

          // شرائح التصفية (Chips Filter)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                _filterChip('all', 'الكل (${_users.length})'),
                _filterChip('admin', 'المشرفين'),
                _filterChip('contributor', 'المساهمين'),
                _filterChip('blocked', 'المحظورين'),
              ],
            ),
          ),

          const Divider(height: 1),

          // قائمة المستخدمين
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : displayedList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          _search.text.isNotEmpty
                              ? 'لا توجد نتائج مطابقة للبحث'
                              : 'لا يوجد مستخدمون',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: displayedList.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, indent: 68),
                    itemBuilder: (context, index) {
                      final u = displayedList[index];
                      final id = u['id'] as int;
                      final canContribute = u['can_contribute'] ?? true;
                      final isAdmin = u['role'] == 'admin';
                      final isSelected = _selectedIds.contains(id);

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.15,
                        ),
                        onTap: () => _showUserDetails(u),
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isAdmin)
                              Checkbox(
                                value: isSelected,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedIds.add(id);
                                    } else {
                                      _selectedIds.remove(id);
                                    }
                                  });
                                },
                              )
                            else
                              const SizedBox(width: 24), // موازاة المسافة عند غياب Checkbox
                            CircleAvatar(
                              backgroundColor: isAdmin
                                  ? Colors.amber.shade700
                                  : (canContribute ? theme.colorScheme.primary : Colors.grey),
                              child: Text(
                                (u['name'] ?? '?').toString()[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                u['name'] ?? 'مستخدم',
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
                            u['email'] ?? '',
                            if (!isAdmin) (canContribute ? 'مساهم' : 'محظور من المساهمة'),
                            if (u['specialization'] != null) u['specialization'],
                          ].where((s) => s.toString().isNotEmpty).join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        trailing: !isAdmin
                            ? PopupMenuButton<String>(
                                onSelected: (val) {
                                  if (val == 'toggle') _toggleContribution(u);
                                  if (val == 'delete') _deleteUser(u);
                                },
                                itemBuilder: (ctx) => [
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
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String role, String label) {
    final selected = _selectedRoleFilter == role;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: FilterChip(
        selected: selected,
        label: Text(label),
        onSelected: (_) {
          setState(() {
            _selectedRoleFilter = role;
          });
        },
      ),
    );
  }
}
