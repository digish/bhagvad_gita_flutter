import 'package:home_widget/home_widget.dart';
import '../models/shloka_result.dart';
import 'deep_link_service.dart';

class HomeWidgetService {
  static const String appGroupId =
      'group.org.komal.bhagvadgeeta'; // Replace with actual Group ID if using one
  static const String androidWidgetName = 'DailyShlokaWidget';
  static const String iOSWidgetName = 'DailyShlokaWidget';

  static const String keyShlokaText = 'shloka_text';
  static const String keyTranslation = 'translation';
  static const String keyChapterShloka = 'chapter_shloka';
  static const String keySpeaker = 'speaker';
  static const String keyShlokaId = 'shloka_id';

  static const String keyHeader = 'header_text';

  static Future<void> updateWidgetData(
    ShlokaResult shloka, {
    String header = 'Daily Gita Wisdom',
  }) async {
    // Required for iOS to know which App Group to use
    await HomeWidget.setAppGroupId(appGroupId);

    final shlokaId = '${shloka.chapterNo}.${shloka.shlokNo}';

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
    await HomeWidget.saveWidgetData<String>(keyShlokaId, shlokaId);

    // Trigger widget update
    await HomeWidget.updateWidget(
      name: androidWidgetName,
      iOSName: iOSWidgetName,
    );
  }

  /// Last shloka shown on the home widget, if any.
  static Future<String?> getCurrentShlokaId() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
      return await HomeWidget.getWidgetData<String>(keyShlokaId);
    } catch (_) {
      return null;
    }
  }

  static Uri launchUriFor(String shlokaId) =>
      DeepLinkService.uriForShloka(shlokaId);

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
    if (shloka.matchSnippet != null && shloka.matchSnippet!.isNotEmpty) {
      return shloka.matchSnippet!;
    }

    if (shloka.categorySnippets != null) {
      if (shloka.categorySnippets!.containsKey('bhavarth')) {
        return shloka.categorySnippets!['bhavarth']!;
      }
      if (shloka.categorySnippets!.containsKey('meaning')) {
        return shloka.categorySnippets!['meaning']!;
      }
      if (shloka.categorySnippets!.containsKey('anvay')) {
        return shloka.categorySnippets!['anvay']!;
      }
    }

    if (shloka.bhavarth.isNotEmpty) return shloka.bhavarth;

    return "Click to read meaning";
  }
}
