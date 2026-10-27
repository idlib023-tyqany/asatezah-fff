import 'dart:async';

import 'package:flutter/material.dart';

// قم بالتأكد من استيراد كلاس AdminService الصحيح هنا
import 'package:asatezah/features/admin/admin_dashboard/admin_dashboard_service.dart';
import './admin_users_view.dart';

class AdminUsers extends StatefulWidget {
  const AdminUsers({super.key});

  @override
  State<AdminUsers> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<AdminUsers> {
  // استخدام AdminService المتاح في المشروع
  final _admin = AdminService();
  final _search = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _users = [];
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
        _users = (result['data'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
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

  @override
  Widget build(BuildContext context) {
    return AdminUsersView(
      users: _users,
      filteredUsers: _filteredUsers,
      selectedIds: _selectedIds,
      selectedRoleFilter: _selectedRoleFilter,
      searchController: _search,
      isLoading: _loading,
      onSearchChanged: _onSearchChanged,
      onSearchSubmitted: (_) => _load(),
      onClearSearch: () {
        _search.clear();
        _load();
      },
      onRefresh: _load,
      onRoleFilterChanged: (role) => setState(() => _selectedRoleFilter = role),
      onSelectAllFiltered: _selectAllFiltered,
      onSelectionChanged: (id, selected) {
        setState(() {
          if (selected) {
            _selectedIds.add(id);
          } else {
            _selectedIds.remove(id);
          }
        });
      },
      onToggleContribution: _toggleContribution,
      onDeleteUser: _deleteUser,
      onApplyToSelected: _applyToSelected,
    );
  }
}
