/// نموذج البيانات (Data Model) لنظام الترقيم القادم من الـ API
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

    final currentPage = int.tryParse(meta['current_page']?.toString() ?? '') ?? 1;
    final lastPage = int.tryParse(meta['last_page']?.toString() ?? '') ?? 1;
    final total = int.tryParse(meta['total']?.toString() ?? '') ?? rawData.length;
    final perPage =
        int.tryParse(meta['per_page']?.toString() ?? '') ??
        (rawData.isNotEmpty ? rawData.length : 20);

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
