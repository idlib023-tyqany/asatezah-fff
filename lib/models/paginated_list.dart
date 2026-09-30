import 'package:flutter/material.dart';

/// 1. نموذج البيانات (Data Model) لنظام الترقيم القادم من الـ API
class PaginatedList<T> {
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;

  const PaginatedList({
    required this.items,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.perPage = 20,
  });

  /// Getter لإعادة الأغراض باسم `files` لتوافقه مع بعض شاشات المكتبة
  List<T> get files => items;

  /// Getters إضافية للخدمات والتحقق من الصفحات
  int get totalPages => lastPage;
  bool get hasNext => currentPage < lastPage;
  bool get hasMore => hasNext;

  /// إنشاء كائن فارغ بأمان
  factory PaginatedList.empty() {
    return const PaginatedList(items: []);
  }

  /// تحويل الـ JSON القادم من السيرفر إلى نموذج البيانات بشكل آمن
  factory PaginatedList.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromJsonT,
  ) {
    // استخراج القائمة الخام
    final rawData = json['data'] is List ? json['data'] as List<dynamic> : [];

    // استخراج معلومات الترقيم من الجذر أو من كائن meta
    final meta = json['meta'] is Map<String, dynamic> ? json['meta'] as Map<String, dynamic> : json;

    final currentPage = meta['current_page'] as int? ?? 1;
    final lastPage = meta['last_page'] as int? ?? 1;
    final total = meta['total'] as int? ?? rawData.length;
    final perPage = meta['per_page'] as int? ?? (rawData.isNotEmpty ? rawData.length : 20);

    // تحويل العناصر إلى النوع T بأمان
    final items = rawData
        .whereType<Map<String, dynamic>>()
        .map((item) {
          try {
            return fromJsonT(item);
          } catch (_) {
            return null;
          }
        })
        .whereType<T>()
        .toList();

    return PaginatedList<T>(
      items: items,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
      perPage: perPage,
    );
  }
}

/// 2. مكون الواجهة (Widget) لعرض القوائم المرقّمة مع دعم السحب للتحديث والتحميل التلقائي
class PaginatedListView<T> extends StatefulWidget {
  final List<T> items;
  final bool isLoadingMore;
  final bool hasMorePages;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget? emptyWidget;
  final Widget? errorWidget;
  final EdgeInsetsGeometry? padding;

  const PaginatedListView({
    super.key,
    required this.items,
    required this.isLoadingMore,
    required this.hasMorePages,
    required this.onRefresh,
    required this.onLoadMore,
    required this.itemBuilder,
    this.emptyWidget,
    this.errorWidget,
    this.padding,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxExtent = _scrollController.position.maxScrollExtent;
    if (maxExtent <= 0) return;

    if (_scrollController.position.pixels >= maxExtent * 0.8) {
      if (!widget.isLoadingMore && widget.hasMorePages) {
        widget.onLoadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.errorWidget != null && widget.items.isEmpty && !widget.isLoadingMore) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            alignment: Alignment.center,
            child: widget.errorWidget,
          ),
        ),
      );
    }

    if (widget.items.isEmpty && !widget.isLoadingMore) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            alignment: Alignment.center,
            child:
                widget.emptyWidget ??
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'لا توجد عناصر لعرضها',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: widget.padding ?? const EdgeInsets.all(16.0),
        itemCount: widget.items.length + (widget.hasMorePages ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == widget.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(child: CircularProgressIndicator.adaptive()),
            );
          }

          return widget.itemBuilder(context, widget.items[index], index);
        },
      ),
    );
  }
}
