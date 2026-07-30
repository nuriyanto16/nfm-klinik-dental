import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nina_dental_care/main.dart';

void main() {
  testWidgets('Home page shows the quick menu and bottom nav', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: NinaDentalCareApp()));
    await tester.pumpAndSettle();

    expect(find.text('Nina Dental Care'), findsWidgets);
    expect(find.text('Reservasi'), findsWidgets);
    expect(find.text('Profil'), findsWidgets);
    expect(find.text('Lengkapi Profil'), findsOneWidget);
  });
}
