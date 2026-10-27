import 'package:asatezah/core/models/paginated_list.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaginatedList.fromJson', () {
    test('reads nested pagination metadata and maps list items', () {
      final page = PaginatedList<int>.fromJson({
        'data': [
          {'value': 7},
          {'value': 11},
        ],
        'meta': {'current_page': 2, 'last_page': 4, 'per_page': 2, 'total': 8},
      }, (json) => json['value'] as int);

      expect(page.items, [7, 11]);
      expect(page.currentPage, 2);
      expect(page.lastPage, 4);
      expect(page.perPage, 2);
      expect(page.total, 8);
      expect(page.hasNext, isTrue);
    });

    test(
      'skips malformed items and applies defaults when metadata is absent',
      () {
        final page = PaginatedList<int>.fromJson({
          'data': [
            {'value': 7},
            {'value': 'invalid'},
            'not-an-object',
          ],
        }, (json) => json['value'] as int);

        expect(page.items, [7]);
        expect(page.currentPage, 1);
        expect(page.lastPage, 1);
        expect(page.perPage, 3);
        expect(page.total, 3);
        expect(page.hasNext, isFalse);
      },
    );
  });
}
