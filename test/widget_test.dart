import 'package:flutter_test/flutter_test.dart';
import 'package:metronome_tap/main.dart';

void main() {
  testWidgets('metronome_tap smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MetronomeTapApp());

    expect(find.byType(MetronomeTapApp), findsOneWidget);
  });
}
