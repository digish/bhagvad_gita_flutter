import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Use relative paths for your own project files
import 'package:bhagvadgeeta/models/shloka_result.dart';
import 'package:bhagvadgeeta/ui/widgets/shloka_result_card.dart';

void main() {
  testWidgets('ShlokaResultCard shows shloka data correctly', (WidgetTester tester) async {
    // 1. ARRANGE: Create some mock shloka data.
    // We don't need to fill all fields, only the ones the card displays.
    final mockShloka = ShlokaResult(
      id: 1,
      chapterNo: '1',
      shlokNo: '1',
      speaker: 'Dhritarashtra',
      tag: null,
      annotation: null,
      shlok: 'dhṛtarāṣṭra uvāca | dharmakṣetre kurukṣetre samavetā yuyutsavaḥ | māmakāḥ pāṇḍavāścaiva kimakurvata sañjaya ||1-1||',
      anvay: '',
      bhavarth: '',
    );

    // 2. ACT: Render the widget.
    // We wrap it in MaterialApp and Scaffold to provide a realistic app environment
    // with themes, text styles, and directionality.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShlokaResultCard(shloka: mockShloka),
        ),
      ),
    );

    // 3. ASSERT: Check if the correct text appears on the screen.
    // 'findsOneWidget' is a Matcher that confirms the text is found exactly once.
    expect(find.text('Chapter 1, Shloka 1'), findsOneWidget);
    
    // We use 'findsOneWidget' again to check for a piece of the shloka text.
    expect(find.textContaining('dharmakṣetre kurukṣetre'), findsOneWidget);
  });
}