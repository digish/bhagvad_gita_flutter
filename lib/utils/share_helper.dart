class ShareHelper {
  static String formatShlokaText(String text) {
    return text
        .replaceAll('<C>', '\n') // Replace center marker with newline
        .replaceAll('*', '\n') // Replace couplet separator with newline
        .replaceAll(RegExp(r'॥\s?[०-९\-]+॥'), '॥') // Clean up shloka numbers
        .trim();
  }

  static const String appLink =
      'https://digish.github.io/project/index.html#bhagvadgita';
}
