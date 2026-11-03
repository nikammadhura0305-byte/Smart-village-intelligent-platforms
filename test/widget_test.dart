import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramsaksham_app/main.dart';
import 'package:gramsaksham_app/app_ui.dart' as app_ui;
import 'package:gramsaksham_app/language/app_language.dart';
import 'package:gramsaksham_app/screens/home/ai_sahayak_screen.dart';
import 'package:gramsaksham_app/screens/home/citizen_home_screen.dart';
import 'package:gramsaksham_app/screens/home/notifications_screen.dart';
import 'package:gramsaksham_app/screens/complaints/report_problem_screen.dart';
import 'package:gramsaksham_app/screens/complaints/location_map_screen.dart';
import 'package:gramsaksham_app/screens/complaints/voice_recording_screen.dart';
import 'package:gramsaksham_app/screens/complaints/complaint_preview_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  SharedPreferences.setMockInitialValues({});

  test('speech locale follows the selected language without substitution', () {
    expect(speechLocaleForLanguage('Marathi'), 'mr-IN');
    expect(speechLocaleForLanguage('Hindi'), 'hi-IN');
    expect(speechLocaleForLanguage('English'), 'en-IN');
    expect(speechLocaleForLanguage('Hindi'), isNot('en-IN'));
  });

  testWidgets('GramSaksham app starts successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GramSakshamApp());
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.byType(GramSakshamApp), findsOneWidget);
  });

  testWidgets('selected language updates mounted app text', (
    WidgetTester tester,
  ) async {
    final language = AppLanguage.instance;
    await language.setLanguage('Marathi');

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: app_ui.Text('समस्या नोंदवा'),
        ),
      ),
    );
    expect(find.text('समस्या नोंदवा'), findsOneWidget);

    await language.setLanguage('Hindi');
    await tester.pump();
    expect(find.text('समस्या दर्ज करें'), findsOneWidget);

    await language.setLanguage('English');
    await tester.pump();
    expect(find.text('Report a problem'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getString('app_language'),
      'English',
    );

    await language.setLanguage('Marathi');
  });

  testWidgets('assistant replies in the selected language', (
    WidgetTester tester,
  ) async {
    final language = AppLanguage.instance;
    await language.setLanguage('Marathi');

    await tester.pumpWidget(
      const MaterialApp(home: AiSahayakScreen()),
    );
    await tester.enterText(find.byType(TextField), 'पाणी आले नाही');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('पाणीपुरवठ्याची समस्या'), findsOneWidget);

    await language.setLanguage('English');
    await tester.pump();
    expect(find.textContaining('To report a water-supply problem'),
        findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_comment_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'The road is damaged');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('For a road problem'), findsOneWidget);

    await language.setLanguage('Hindi');
    await tester.pump();
    expect(find.textContaining('सड़क की समस्या के लिए'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('home screen labels follow the selected language', (
    WidgetTester tester,
  ) async {
    final language = AppLanguage.instance;
    await language.setLanguage('Hindi');

    await tester.pumpWidget(
      const MaterialApp(home: CitizenHomeScreen()),
    );
    expect(find.text('नमस्ते!'), findsOneWidget);
    expect(find.text('समस्या दर्ज करें'), findsOneWidget);
    expect(find.text('मेरी शिकायतें'), findsOneWidget);
    expect(find.text('सूचनाएँ'), findsWidgets);
    expect(find.text('AI सहायक'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await language.setLanguage('English');
    await tester.pump();
    expect(find.text('Hello!'), findsOneWidget);
    expect(find.text('Report a problem'), findsOneWidget);
    expect(find.text('My complaints'), findsOneWidget);

    await language.setLanguage('Marathi');
    await tester.pump();
    expect(find.text('नमस्कार!'), findsOneWidget);
    expect(find.text('समस्या नोंदवा'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('notifications and categories localize across device widths', (
    WidgetTester tester,
  ) async {
    final language = AppLanguage.instance;
    await language.setLanguage('Hindi');
    await tester.pumpWidget(
      const MaterialApp(home: NotificationsScreen()),
    );
    expect(find.text('शिकायत अपडेट'), findsOneWidget);
    expect(find.text('ग्रामसक्षम में आपका स्वागत है!'), findsOneWidget);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const MaterialApp(home: ReportProblemScreen()));
    final mobileGrid = tester.widget<GridView>(find.byType(GridView));
    expect(
      (mobileGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      2,
    );
    expect(find.text('पानी की समस्या'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(const Size(1100, 900));
    await tester.pumpWidget(const MaterialApp(home: ReportProblemScreen()));
    final desktopGrid = tester.widget<GridView>(find.byType(GridView));
    expect(
      (desktopGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      5,
    );
    final categoryImages = tester.widgetList<Image>(find.byType(Image)).where(
      (image) {
        final provider = image.image;
        return provider is AssetImage &&
            provider.assetName.startsWith('assets/images/complaints/');
      },
    );
    expect(categoryImages, hasLength(10));
    expect(categoryImages.every((image) => image.fit == BoxFit.cover), isTrue);
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(null);
    await tester.pumpWidget(const SizedBox.shrink());
    await language.setLanguage('Marathi');
  });

  testWidgets('voice complaint labels follow the selected language', (
    WidgetTester tester,
  ) async {
    final language = AppLanguage.instance;
    await language.setLanguage('Hindi');

    await tester.pumpWidget(
      MaterialApp(
        home: VoiceRecordingScreen(
          language: 'Hindi',
          onVoiceResult: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('आवाज़ से शिकायत'), findsOneWidget);
    expect(find.text('अपनी समस्या बोलें'), findsOneWidget);
    expect(find.text('चुनी गई भाषा: हिंदी'), findsOneWidget);
    expect(find.text('पहचाना गया पाठ'), findsOneWidget);
    expect(find.text('उदा. आज पानी नहीं आया।'), findsOneWidget);

    await language.setLanguage('English');
    await tester.pump();
    expect(find.text('Voice complaint'), findsOneWidget);
    expect(find.text('Speak about your problem'), findsOneWidget);
    expect(find.text('Selected language: English'), findsOneWidget);
    expect(find.text('Recognized text'), findsOneWidget);

    await language.setLanguage('Marathi');
    await tester.pump();
    expect(find.text('आवाजातून तक्रार'), findsOneWidget);
    expect(find.text('तुमची समस्या बोला'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('location screen labels follow the selected language', (
    WidgetTester tester,
  ) async {
    final language = AppLanguage.instance;
    await language.setLanguage('Hindi');
    await tester.binding.setSurfaceSize(const Size(800, 1500));

    await tester.pumpWidget(
      const MaterialApp(
        home: LocationMapScreen(
          category: 'Water',
          location: '',
          description: '',
          attachment: null,
          isVideo: false,
        ),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('वर्तमान GPS स्थान'));
    await tester.pump();
    expect(find.text('महाराष्ट्र में गाँव चुनें'), findsOneWidget);
    expect(find.text('जिला'), findsOneWidget);
    expect(find.text('तालुका'), findsOneWidget);
    expect(find.text('गाँव'), findsOneWidget);
    expect(find.text('GPS स्थान'), findsOneWidget);
    expect(find.text('अपना स्थान तय करें'), findsOneWidget);
    expect(find.text('वर्तमान GPS स्थान'), findsOneWidget);
    expect(find.text('जिला'), findsOneWidget);
    expect(find.text('तालुका'), findsOneWidget);
    expect(find.text('गाँव'), findsOneWidget);
    expect(find.text('GPS स्थान उपलब्ध नहीं है।'), findsNothing);
    expect(tester.takeException(), isNull);

    await language.setLanguage('English');
    await tester.pump();
    expect(find.text('Confirm your location'), findsOneWidget);
    expect(find.text('Current GPS location'), findsOneWidget);
    expect(find.text('District'), findsOneWidget);
    expect(find.text('Taluka'), findsOneWidget);
    expect(find.text('Village'), findsOneWidget);

    await language.setLanguage('Marathi');
    await tester.pump();
    expect(find.text('तुमचे ठिकाण निश्चित करा'), findsOneWidget);
    expect(find.text('जिल्हा'), findsOneWidget);
    expect(find.text('तालुका'), findsOneWidget);
    expect(find.text('गाव'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('complaint review localizes labels and keeps GPS coordinates', (
    WidgetTester tester,
  ) async {
    final language = AppLanguage.instance;
    await language.setLanguage('Hindi');

    await tester.pumpWidget(
      const MaterialApp(
        home: ComplaintPreviewScreen(
          category: 'Water',
          location: 'Wagholi, Haveli, Pune, Maharashtra',
          description: 'Water supply stopped',
          liveGpsCoordinates: '18.520430, 73.856744',
        ),
      ),
    );
    expect(find.text('शिकायत की समीक्षा'), findsOneWidget);
    expect(find.text('शिकायत का गाँव'), findsOneWidget);
    expect(find.text('Wagholi, Haveli, Pune, Maharashtra'), findsOneWidget);
    expect(find.text('18.520430, 73.856744'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await language.setLanguage('English');
    await tester.pump();
    expect(find.text('Review complaint'), findsOneWidget);
    expect(find.text('Actual device GPS coordinates'), findsOneWidget);

    await language.setLanguage('Marathi');
    await tester.pump();
    expect(find.text('तक्रारीचा आढावा'), findsOneWidget);
    expect(find.text('प्रत्यक्ष GPS निर्देशांक'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.binding.setSurfaceSize(null);
    await language.setLanguage('Marathi');
  });
}
