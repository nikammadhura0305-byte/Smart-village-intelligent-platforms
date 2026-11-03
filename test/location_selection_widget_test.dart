import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramsaksham_app/language/app_language.dart';
import 'package:gramsaksham_app/screens/complaints/location_map_screen.dart';
import 'package:gramsaksham_app/services/maharashtra_location_search.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('selecting district, taluka, and village positions the map', (
    WidgetTester tester,
  ) async {
    await AppLanguage.instance.setLanguage('English');
    await tester.binding.setSurfaceSize(const Size(800, 1500));
    final service = MaharashtraLocationSearch(
      client: _MaharashtraSearchClient(),
      minimumRequestInterval: Duration.zero,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LocationMapScreen(
          category: 'Water',
          location: '',
          description: 'Water supply stopped',
          attachment: null,
          isVideo: false,
          searchService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _selectLocationResult(tester, 'Pune', 'Pune');
    await _selectLocationResult(
      tester,
      'Haveli',
      'Haveli Subdistrict',
    );
    await _selectLocationResult(tester, 'Wagholi', 'Wagholi');

    expect(
      find.text('Wagholi, Haveli Subdistrict, Pune, Maharashtra'),
      findsOneWidget,
    );
    expect(find.byType(FlutterMap), findsOneWidget);
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    expect(map.options.initialCenter.latitude, 18.58);
    expect(map.options.initialCenter.longitude, 73.98);

    final markers = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    expect(markers.markers, hasLength(1));
    expect(markers.markers.single.point.latitude, 18.58);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.binding.setSurfaceSize(null);
    await AppLanguage.instance.setLanguage('Marathi');
  });
}

Future<void> _selectLocationResult(
  WidgetTester tester,
  String query,
  String result,
) async {
  await tester.tap(find.text('Tap to search').first);
  await tester.pumpAndSettle();

  final dialog = find.byType(AlertDialog);
  final searchField = find.descendant(
    of: dialog,
    matching: find.byType(TextField),
  );
  await tester.enterText(searchField, query);
  await tester.tap(find.widgetWithText(FilledButton, 'Search'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ListTile, result).first);
  if (result == 'Wagholi') {
    await tester.pump(const Duration(milliseconds: 500));
  } else {
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  }
}

class _MaharashtraSearchClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final query = request.url.queryParameters['q'] ?? '';
    final result = query.startsWith('Wagholi')
        ? _village
        : query.startsWith('Haveli')
            ? _taluka
            : _district;
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode([result]))),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

const _district = {
  'name': 'Pune',
  'display_name': 'Pune, Maharashtra, India',
  'lat': '18.6448627',
  'lon': '73.9224157',
  'osm_type': 'relation',
  'osm_id': 1,
  'category': 'boundary',
  'type': 'administrative',
  'addresstype': 'state_district',
  'address': {
    'state_district': 'Pune District',
    'state': 'Maharashtra',
    'ISO3166-2-lvl4': 'IN-MH',
  },
};

const _taluka = {
  'name': 'Haveli Subdistrict',
  'display_name': 'Haveli Subdistrict, Pune District, Maharashtra, India',
  'lat': '18.5105199',
  'lon': '74.0609353',
  'osm_type': 'relation',
  'osm_id': 2,
  'category': 'boundary',
  'type': 'administrative',
  'addresstype': 'county',
  'address': {
    'county': 'Haveli Subdistrict',
    'state_district': 'Pune District',
    'state': 'Maharashtra',
    'ISO3166-2-lvl4': 'IN-MH',
  },
};

const _village = {
  'name': 'Wagholi',
  'display_name':
      'Wagholi, Haveli Subdistrict, Pune District, Maharashtra, India',
  'lat': '18.58',
  'lon': '73.98',
  'osm_type': 'node',
  'osm_id': 3,
  'category': 'place',
  'type': 'village',
  'addresstype': 'village',
  'address': {
    'village': 'Wagholi',
    'county': 'Haveli Subdistrict',
    'state_district': 'Pune District',
    'state': 'Maharashtra',
    'ISO3166-2-lvl4': 'IN-MH',
  },
};
