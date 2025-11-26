import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ropacalapp/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: RopacalApp()));

    expect(find.text('Welcome to Ropacal'), findsOneWidget);
    expect(
      find.text('Built with Flutter, Riverpod & Supabase'),
      findsOneWidget,
    );
  });
}
