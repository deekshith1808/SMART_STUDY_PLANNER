import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_study_planner/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App smoke test - verifies StudySmartApp renders WelcomeScreen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const StudySmartApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Spark'), findsOneWidget);
    expect(find.text('Start Learning 📖'), findsOneWidget);
  });
}
