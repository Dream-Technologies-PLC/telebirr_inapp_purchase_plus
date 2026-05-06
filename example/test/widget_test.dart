import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telebirr_inapp_purchase_plus_example/main.dart';

void main() {
  testWidgets('shows Telebirr payment form', (tester) async {
    await tester.pumpWidget(const TelebirrExampleApp());

    expect(find.text('Telebirr InApp Purchase Plus'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Create Order From Backend'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Create Order From Backend'), findsOneWidget);
    expect(find.text('Pay With Telebirr'), findsOneWidget);
  });
}
