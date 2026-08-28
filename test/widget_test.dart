import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stumble_brawl/main.dart';

void main() {
  testWidgets('App loads MainMenu', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: StumbleBrawlApp()));
    await tester.pump();
    expect(find.textContaining('STUMBLE'), findsOneWidget);
    expect(find.text('JOGAR'), findsOneWidget);
  });
}
