import 'package:home_widget/home_widget.dart';
import '../models/shloka_result.dart';

class HomeWidgetService {
  static const String appGroupId =
      'group.org.komal.bhagvadgeeta'; // Replace with actual Group ID if using one
  static const String androidWidgetName = 'DailyShlokaWidget';
  static const String iOSWidgetName = 'DailyShlokaWidget';

  static const String keyShlokaText = 'shloka_text';
  static const String keyTranslation = 'translation';
  static const String keyChapterShloka = 'chapter_shloka';
  static const String keySpeaker = 'speaker';

  static const String keyHeader = 'header_text';

  static Future<void> updateWidgetData(
    ShlokaResult shloka, {
    String header = 'Daily Gita Wisdom',
  }) async {
    // Required for iOS to know which App Group to use
    await HomeWidget.setAppGroupId(appGroupId);

    // Save data to the widget shared storage
    await HomeWidget.saveWidgetData<String>(
      keyHeader,
      header.toUpperCase(), // Ensure uppercase for style
    );
    await HomeWidget.saveWidgetData<String>(
      keyShlokaText,
      _processShlokaText(shloka.shlok),
    );
    await HomeWidget.saveWidgetData<String>(
      keyTranslation,
      _getBestTranslation(shloka),
    );
    await HomeWidget.saveWidgetData<String>(
      keyChapterShloka,
      'Chapter ${shloka.chapterNo}, Shloka ${shloka.shlokNo}',
    );
    await HomeWidget.saveWidgetData<String>(keySpeaker, shloka.speaker);

    // Trigger widget update
    await HomeWidget.updateWidget(
      name: androidWidgetName,
      iOSName: iOSWidgetName,
    );
  }

  // Helper to extract clean text (similar to SearchScreen)
  static String _processShlokaText(String rawText) {
    String processed = rawText.replaceAll(RegExp(r'॥\s?[०-९\-]+॥'), '॥');
    final couplets = processed.split('*');
    final allLines = <String>[];

    for (var couplet in couplets) {
      final parts = couplet.split('<C>');
      for (int i = 0; i < parts.length; i++) {
        String line = parts[i].trim();
        if (line.isNotEmpty) {
          allLines.add(line);
        }
      }
    }
    return allLines.join('\n');
  }

  static String _getBestTranslation(ShlokaResult shloka) {
    // Prefer Bhavarth (Hindi/English Translation)
    // The model typically has 'bhavarth'
    // If not, check 'meaning' from category snippets if available

    // Check if we have English translation (often stored in translations table)
    // For now, let's use what we have in the model.
    // The ShlokaResult model has 'bhavarth' field? Let's check model definition if needed,
    // but usually 'matchSnippet' or 'bhavarth' is available.
    // Wait, let's look at ShlokaResult definition to be sure.
    // Assuming implicit knowledge or based on previous files:

    // If we look at SearchScreen logic, it uses snippets.

    // Let's use simple fallbacks
    if (shloka.matchSnippet != null && shloka.matchSnippet!.isNotEmpty) {
      return shloka.matchSnippet!;
    }

    // If we have category snippets
    if (shloka.categorySnippets != null) {
      if (shloka.categorySnippets!.containsKey('bhavarth'))
        return shloka.categorySnippets!['bhavarth']!;
      if (shloka.categorySnippets!.containsKey('meaning'))
        return shloka.categorySnippets!['meaning']!;
      if (shloka.categorySnippets!.containsKey('anvay'))
        return shloka.categorySnippets!['anvay']!;
    }

    return "Click to read meaning";
  }
}
