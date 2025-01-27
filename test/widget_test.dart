import 'package:book_finder01/book_finder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Search bar is present and can be interacted with', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(BookFinderApp(username: '',));

    // Verify that the search bar is present.
    expect(find.byType(TextField), findsOneWidget);

    // Enter text into the search bar.
    await tester.enterText(find.byType(TextField), 'Harry Potter');

    // Verify that the text is entered correctly.
    expect(find.text('Harry Potter'), findsOneWidget);
  });

  testWidgets('Search icon triggers search', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(BookFinderApp(username: '',));

    // Enter text into the search bar.
    await tester.enterText(find.byType(TextField), 'Flutter');

    // Tap the search icon.
    await tester.tap(find.byIcon(Icons.search));

    // Trigger a frame after interaction.
    await tester.pump();

    // Simulate a delay for fetching API data.
    await tester.pump(const Duration(seconds: 2));

    // Verify that the list of books is displayed.
    expect(find.byType(ListTile), findsWidgets); // At least one book should be listed.
  });
}
