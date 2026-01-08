import 'package:flutter_test/flutter_test.dart';
import 'package:joinme_app/main.dart';

void main() {
  testWidgets('App starts and shows home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const JoinMeApp());

    // Verify that the app shows the welcome message.
    expect(find.text('Welcome to JoinMe!'), findsOneWidget);
    expect(find.text('Discover activities around you'), findsOneWidget);
  });
}
