import 'package:bhagvadgeeta/models/ask_gita_history_entry.dart';
import 'package:bhagvadgeeta/services/ask_gita_history_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

AskGitaHistoryEntry _entry(int index) => AskGitaHistoryEntry(
      id: 'id_$index',
      askedAtMs: 1_700_000_000_000 + index,
      question: 'Question $index?',
      answer: 'Answer $index',
      referenceIds: ['2.47'],
      language: 'hi',
      script: 'dev',
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('append prepends newest and trims to 20', () async {
    final service = AskGitaHistoryService();

    for (var i = 0; i < 22; i++) {
      await service.append(_entry(i));
    }

    final loaded = await service.load();
    expect(loaded.length, AskGitaHistoryService.maxEntries);
    expect(loaded.first.id, 'id_21');
    expect(loaded.last.id, 'id_2');
  });

  test('clearAll removes stored history', () async {
    final service = AskGitaHistoryService();
    await service.append(_entry(1));
    expect((await service.load()).length, 1);

    await service.clearAll();
    expect(await service.load(), isEmpty);
  });

  test('skips entries with empty answer', () async {
    final service = AskGitaHistoryService();
    await service.append(
      AskGitaHistoryEntry(
        id: 'empty',
        askedAtMs: 1,
        question: 'Q?',
        answer: '   ',
        referenceIds: [],
        language: 'hi',
        script: 'dev',
      ),
    );
    expect(await service.load(), isEmpty);
  });
}
