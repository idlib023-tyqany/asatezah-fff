import 'package:asatezah/core/models/paginated_list.dart';
import 'package:asatezah/features/library/folders/folder_model.dart';
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

  test('folder and file models parse the folder API response', () {
    final contents = FolderContents.fromJson({
      'id': 12,
      'name': 'الرياضيات',
      'parent_id': null,
      'category_id': 2,
      'files': [
        {
          'id': 34,
          'title': 'ملخص الجبر',
          'filename': 'algebra.pdf',
          'mime_type': 'application/pdf',
          'raw_file_size': 2048,
          'status': 'published',
          'stats': {'downloads_count': 3},
          'created_at': '2026-10-30T12:00:00Z',
        },
      ],
    });

    expect(contents.folder.id, 12);
    expect(contents.folder.name, 'الرياضيات');
    expect(contents.files.single.id, 34);
    expect(contents.files.single.fileSize, 2048);
    expect(
      FolderItem.fromJson({'id': 12, 'name': 'الرياضيات', 'files_count': 1})
          .filesCount,
      1,
    );
  });
}
