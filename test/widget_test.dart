import 'package:flutter_test/flutter_test.dart';
import 'package:memonest/main.dart';

void main() {
  test('starter notes contain useful sample categories', () {
    final notes = starterNotes();
    expect(notes, isNotEmpty);
    expect(notes.any((note) => note.category == 'Study'), isTrue);
    expect(notes.any((note) => note.pinned), isTrue);
  });

  test('note JSON round trip preserves title and tags', () {
    final original = MemoNote(
      id: 'test-1',
      title: 'Flutter revision',
      body: 'Widget testing',
      category: 'Study',
      colorValue: 0xFFEDE9FE,
      updatedAt: DateTime(2026, 1, 1),
      tags: const ['flutter', 'test'],
      pinned: true,
    );
    final copy = MemoNote.fromJson(original.toJson());
    expect(copy.title, original.title);
    expect(copy.tags, original.tags);
    expect(copy.pinned, isTrue);
  });
}
