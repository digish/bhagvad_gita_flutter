import 'package:flutter/material.dart';

/// Typography and speaker washes for chapter / continuous verse reading.
/// Tuned for amber chapter gradients (light) and gold-accent dark theme.
@immutable
class ChapterReadingColors {
  final Color speakerKrishna;
  final Color speakerArjuna;
  final Color speakerSanjay;
  final Color speakerDhritarashtra;
  final Color speakerDefault;

  final Color shloka;
  final Color shlokaFourLine;
  final Color anvay;
  final Color tika;
  final Color karaokeHighlight;

  const ChapterReadingColors({
    required this.speakerKrishna,
    required this.speakerArjuna,
    required this.speakerSanjay,
    required this.speakerDhritarashtra,
    required this.speakerDefault,
    required this.shloka,
    required this.shlokaFourLine,
    required this.anvay,
    required this.tika,
    required this.karaokeHighlight,
  });

  static const light = ChapterReadingColors(
    // Soft washes (~17–20% opacity) — readable on amber gradient + white card.
    speakerKrishna: Color(0x33F9A825), // warm amber (divine)
    speakerArjuna: Color(0x38EF6C00), // saffron (warrior)
    speakerSanjay: Color(0x33047BC0), // gita blue (narrator)
    speakerDhritarashtra: Color(0x38795548), // earth brown (king)
    speakerDefault: Color(0x1A1C1917),
    shloka: Color(0xFF1C1917), // warm ink
    shlokaFourLine: Color(0xFF5B21B6), // measured violet (four-line)
    anvay: Color(0xFF3D4F6F), // slate blue-grey
    tika: Color(0xFF5C4A3A), // warm brown prose
    karaokeHighlight: Color(0xFF047BC0), // brand blue on ink / violet
  );

  static const dark = ChapterReadingColors(
    speakerKrishna: Color(0x40FFC107), // muted gold
    speakerArjuna: Color(0x38FF9800), // deep orange
    speakerSanjay: Color(0x4042A5F5), // calm blue
    speakerDhritarashtra: Color(0x40A1887F), // dusty rose-brown
    speakerDefault: Color(0x14FFFFFF),
    shloka: Color(0xFFF2EDE4), // warm off-white
    shlokaFourLine: Color(0xFFD4C4F5), // soft lavender
    anvay: Color(0xFFB4BDD4), // cool mist
    tika: Color(0xFFC9B89A), // parchment tan
    karaokeHighlight: Color(0xFFFFB300), // amber (readable on warm text)
  );

  static ChapterReadingColors of(Brightness brightness) =>
      brightness == Brightness.light ? light : dark;

  Color speakerTint(String? speaker) {
    switch (speaker?.toLowerCase()) {
      case 'श्री भगवान':
        return speakerKrishna;
      case 'अर्जुन':
        return speakerArjuna;
      case 'संजय':
        return speakerSanjay;
      case 'धृतराष्ट्र':
        return speakerDhritarashtra;
      default:
        return speakerDefault;
    }
  }
}
