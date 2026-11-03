import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gramsaksham_app/services/maharashtra_location_search.dart';
import 'package:http/http.dart' as http;

void main() {
  test('search results are filtered to the requested Maharashtra hierarchy',
      () async {
    final client = _LocationSearchClient(_results);
    final service = MaharashtraLocationSearch(
      client: client,
      minimumRequestInterval: Duration.zero,
    );

    final districtResults = await service.search(
      level: MaharashtraLocationLevel.district,
      query: 'Pune',
      languageCode: 'en',
    );
    expect(districtResults.map((result) => result.name), ['Pune']);

    final talukaResults = await service.search(
      level: MaharashtraLocationLevel.taluka,
      query: 'Haveli',
      district: 'Pune',
      languageCode: 'en',
    );
    expect(talukaResults.map((result) => result.name), ['Haveli Subdistrict']);
    expect(
      client.requestedUris.last.queryParameters['q'],
      'Haveli, Pune, Maharashtra, India',
    );

    final villageResults = await service.search(
      level: MaharashtraLocationLevel.village,
      query: 'Wagholi',
      district: 'Pune',
      taluka: 'Haveli Subdistrict',
      languageCode: 'en',
    );
    expect(villageResults.map((result) => result.name), ['Wagholi']);
    expect(villageResults.single.point.latitude, 18.58);
    expect(
      client.requestedUris.last.queryParameters['q'],
      'Wagholi, Haveli Subdistrict, Pune, Maharashtra, India',
    );
  });
}

class _LocationSearchClient extends http.BaseClient {
  _LocationSearchClient(this.body);

  final List<Map<String, Object>> body;
  final requestedUris = <Uri>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestedUris.add(request.url);
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(body))),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

final List<Map<String, Object>> _results = [
  {
    'name': 'Pune',
    'display_name': 'Pune, Maharashtra, India',
    'lat': '18.5204',
    'lon': '73.8567',
    'osm_type': 'relation',
    'osm_id': 1,
    'category': 'boundary',
    'type': 'administrative',
    'addresstype': 'state_district',
    'address': {'state': 'Maharashtra', 'state_district': 'Pune'},
  },
  {
    'name': 'Haveli Subdistrict',
    'display_name': 'Haveli Subdistrict, Pune, Maharashtra, India',
    'lat': '18.55',
    'lon': '73.9',
    'osm_type': 'relation',
    'osm_id': 2,
    'category': 'boundary',
    'type': 'administrative',
    'addresstype': 'county',
    'address': {
      'state': 'Maharashtra',
      'state_district': 'Pune',
      'county': 'Haveli Subdistrict',
    },
  },
  {
    'name': 'Wagholi',
    'display_name': 'Wagholi, Haveli, Pune, Maharashtra, India',
    'lat': '18.58',
    'lon': '73.98',
    'osm_type': 'node',
    'osm_id': 3,
    'category': 'place',
    'type': 'village',
    'addresstype': 'village',
    'address': {
      'state': 'Maharashtra',
      'state_district': 'Pune',
      'county': 'Haveli',
      'village': 'Wagholi',
    },
  },
  {
    'name': 'Wagholi',
    'display_name': 'Wagholi, Shirur, Pune, Maharashtra, India',
    'lat': '18.60',
    'lon': '74.00',
    'osm_type': 'node',
    'osm_id': 4,
    'category': 'place',
    'type': 'village',
    'addresstype': 'village',
    'address': {
      'state': 'Maharashtra',
      'state_district': 'Pune',
      'county': 'Shirur',
      'village': 'Wagholi',
    },
  },
  {
    'name': 'Wagholi',
    'display_name': 'Wagholi, Haveli, Karnataka, India',
    'lat': '15.0',
    'lon': '75.0',
    'osm_type': 'node',
    'osm_id': 5,
    'category': 'place',
    'type': 'village',
    'addresstype': 'village',
    'address': {
      'state': 'Karnataka',
      'state_district': 'Pune',
      'county': 'Haveli',
      'village': 'Wagholi',
    },
  },
];
