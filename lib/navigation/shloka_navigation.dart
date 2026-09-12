import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const String _kShlokaListRoutePrefix = '/shloka-list/';

/// In-app path to open a verse inside its chapter list (scroll via `?shloka=`).
String? shlokaListLocationForVerseId(String verseId) {
  final trimmed = verseId.trim();
  final match = RegExp(r'^(\d+)\.(\d+)$').firstMatch(trimmed);
  if (match == null) return null;
  final chapter = match.group(1)!;
  final shloka = match.group(2)!;
  return '$_kShlokaListRoutePrefix$chapter?shloka=$shloka';
}

void pushShlokaInChapter(
  BuildContext context, {
  required String chapterNo,
  required String shlokNo,
}) {
  final shlokaNo = int.tryParse(shlokNo);
  context.push('$_kShlokaListRoutePrefix$chapterNo', extra: shlokaNo);
}

void goShlokaInChapter(GoRouter router, String verseId) {
  final location = shlokaListLocationForVerseId(verseId);
  if (location == null) {
    router.go('/');
    return;
  }
  router.go(location);
}

bool isAlreadyOnShlokaInChapter(String currentLocation, String verseId) {
  final location = shlokaListLocationForVerseId(verseId);
  if (location == null) return false;
  final uri = Uri.parse(location);
  return currentLocation.contains('/shloka-list/${uri.pathSegments.last}') &&
      currentLocation.contains('shloka=${uri.queryParameters['shloka']}');
}
