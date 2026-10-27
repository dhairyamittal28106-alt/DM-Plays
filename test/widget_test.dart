






import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dm_plays/main.dart';

void main() {
  testWidgets('DM Plays app loads correctly', (WidgetTester tester) async {
    
    await tester.pumpWidget(const DmPlaysApp());

    
    expect(find.text('DM PLAYS'), findsOneWidget);

    
    expect(find.byIcon(Icons.home_filled), findsOneWidget);
  });
}
