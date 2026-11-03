import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

enum MaharashtraLocationLevel { district, taluka, village }

class MaharashtraLocationOption {
  const MaharashtraLocationOption({
    required this.name,
    required this.displayName,
    required this.point,
    required this.osmType,
    required this.osmId,
  });

  final String name;
  final String displayName;
  final LatLng point;
  final String osmType;
  final String osmId;

  String get id => '$osmType:$osmId';
}

class MaharashtraLocationSearch {
  MaharashtraLocationSearch({
    http.Client? client,
    this.minimumRequestInterval = const Duration(seconds: 1),
  }) : _client = client ?? http.Client();

  static final instance = MaharashtraLocationSearch();

  final http.Client _client;
  final Duration minimumRequestInterval;
  final Map<String, List<MaharashtraLocationOption>> _cache = {};
  DateTime? _lastRequestAt;
  Future<void> _requestQueue = Future<void>.value();

  Future<List<MaharashtraLocationOption>> search({
    required MaharashtraLocationLevel level,
    required String query,
    String? district,
    String? taluka,
    required String languageCode,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return const [];

    final contextualQuery = switch (level) {
      MaharashtraLocationLevel.district => '$trimmedQuery, Maharashtra, India',
      MaharashtraLocationLevel.taluka =>
        '$trimmedQuery, ${district ?? ''}, Maharashtra, India',
      MaharashtraLocationLevel.village =>
        '$trimmedQuery, ${taluka ?? ''}, ${district ?? ''}, Maharashtra, India',
    };
    final cacheKey =
        '${level.name}|${contextualQuery.toLowerCase()}|$languageCode';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'format': 'jsonv2',
        'addressdetails': '1',
        'limit': '30',
        'countrycodes': 'in',
        'q': contextualQuery,
      },
    );
    final response = await _get(
      uri,
      languageCode: languageCode,
    );
    if (response.statusCode != 200) {
      throw _requestException(response.statusCode);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const MaharashtraLocationSearchException.invalidResponse();
    }

    final results = <MaharashtraLocationOption>[];
    final seen = <String>{};
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      final address = item['address'];
      if (address is! Map<String, dynamic>) continue;

      final displayName = item['display_name'];
      final fullName = displayName?.toString() ?? '';
      if (!_isMaharashtra(address, fullName) ||
          !_matchesLevel(item, level) ||
          (level != MaharashtraLocationLevel.district &&
              !_matchesAdministrativeParent(
                address: address,
                displayName: fullName,
                parent: district ?? '',
                addressKeys: const ['state_district', 'county'],
              )) ||
          (level == MaharashtraLocationLevel.village &&
              !_matchesAdministrativeParent(
                address: address,
                displayName: fullName,
                parent: taluka ?? '',
                addressKeys: const ['county', 'subdistrict', 'municipality'],
              ))) {
        continue;
      }

      final name = item['name']?.toString().trim();
      final latitude = double.tryParse(item['lat']?.toString() ?? '');
      final longitude = double.tryParse(item['lon']?.toString() ?? '');
      final osmType = item['osm_type']?.toString();
      final osmId = item['osm_id']?.toString();
      if (name == null ||
          name.isEmpty ||
          fullName.isEmpty ||
          latitude == null ||
          longitude == null ||
          !latitude.isFinite ||
          !longitude.isFinite ||
          latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180 ||
          osmType == null ||
          osmId == null) {
        continue;
      }

      final option = MaharashtraLocationOption(
        name: name,
        displayName: fullName,
        point: LatLng(latitude, longitude),
        osmType: osmType,
        osmId: osmId,
      );
      if (seen.add(option.id)) results.add(option);
    }

    _cache[cacheKey] = List.unmodifiable(results);
    return _cache[cacheKey]!;
  }

  Future<String?> reverseGeocode({
    required double latitude,
    required double longitude,
    required String languageCode,
  }) async {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/reverse',
      {
        'format': 'jsonv2',
        'addressdetails': '1',
        'zoom': '16',
        'lat': latitude.toString(),
        'lon': longitude.toString(),
      },
    );
    final response = await _get(uri, languageCode: languageCode);
    if (response.statusCode != 200) {
      throw _requestException(response.statusCode);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const MaharashtraLocationSearchException.invalidResponse();
    }
    final address = decoded['display_name']?.toString().trim();
    return address == null || address.isEmpty ? null : address;
  }

  Future<http.Response> _get(
    Uri uri, {
    required String languageCode,
  }) async {
    final previousRequest = _requestQueue;
    final requestSlot = Completer<void>();
    _requestQueue = requestSlot.future;
    await previousRequest;
    final lastRequestAt = _lastRequestAt;
    if (lastRequestAt != null) {
      final wait =
          minimumRequestInterval - DateTime.now().difference(lastRequestAt);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
    }
    _lastRequestAt = DateTime.now();
    requestSlot.complete();

    try {
      return await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Accept-Language': languageCode,
          if (!kIsWeb) 'User-Agent': 'GramSaksham/1.0',
        },
      ).timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const MaharashtraLocationSearchException.timeout();
    } on http.ClientException {
      throw const MaharashtraLocationSearchException.unavailable();
    }
  }

  bool _isMaharashtra(
    Map<String, dynamic> address,
    String displayName,
  ) {
    final state = address['state']?.toString() ?? '';
    final subdivisionCode = address['ISO3166-2-lvl4']?.toString() ?? '';
    return subdivisionCode == 'IN-MH' ||
        _containsIgnoreCase(state, 'Maharashtra') ||
        _containsIgnoreCase(displayName, 'Maharashtra');
  }

  bool _matchesAdministrativeParent({
    required Map<String, dynamic> address,
    required String displayName,
    required String parent,
    required List<String> addressKeys,
  }) {
    final normalizedParent = _normalizeAdministrativeName(parent);
    if (normalizedParent.isEmpty) return false;

    final candidates = [
      for (final key in addressKeys)
        if (address[key] != null) address[key].toString(),
      ...displayName.split(','),
    ];
    return candidates.any((candidate) {
      final normalizedCandidate = _normalizeAdministrativeName(candidate);
      return normalizedCandidate == normalizedParent ||
          normalizedCandidate.startsWith('$normalizedParent ') ||
          normalizedParent.startsWith('$normalizedCandidate ');
    });
  }

  String _normalizeAdministrativeName(String name) => name
      .toLowerCase()
      .replaceAll(
        RegExp(r'\b(subdistrict|district|taluka|tehsil)\b'),
        ' ',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  bool _matchesLevel(
    Map<String, dynamic> item,
    MaharashtraLocationLevel level,
  ) {
    final address = item['address'];
    if (address is! Map<String, dynamic>) return false;
    final addressType = item['addresstype']?.toString().toLowerCase() ?? '';
    final category = item['category']?.toString().toLowerCase() ?? '';
    final type = item['type']?.toString().toLowerCase() ?? '';

    return switch (level) {
      MaharashtraLocationLevel.district => addressType == 'state_district',
      MaharashtraLocationLevel.taluka => addressType == 'county' ||
          addressType == 'subdistrict' ||
          addressType == 'municipality' ||
          (category == 'boundary' &&
              type == 'administrative' &&
              addressType != 'state_district'),
      MaharashtraLocationLevel.village => addressType == 'village' ||
          addressType == 'hamlet' ||
          addressType == 'town' ||
          addressType == 'suburb' ||
          addressType == 'isolated_dwelling' ||
          addressType == 'locality' ||
          (category == 'place' &&
              const {
                'village',
                'hamlet',
                'town',
                'suburb',
                'isolated_dwelling',
                'locality',
              }.contains(type)),
    };
  }

  bool _containsIgnoreCase(String value, String query) =>
      query.isEmpty || value.toLowerCase().contains(query.toLowerCase());

  MaharashtraLocationSearchException _requestException(int statusCode) {
    if (statusCode == 429) {
      return const MaharashtraLocationSearchException.rateLimited();
    }
    return const MaharashtraLocationSearchException.unavailable();
  }
}

class MaharashtraLocationSearchException implements Exception {
  const MaharashtraLocationSearchException._(this.reason);
  const MaharashtraLocationSearchException.timeout() : this._('timeout');
  const MaharashtraLocationSearchException.unavailable()
      : this._('unavailable');
  const MaharashtraLocationSearchException.rateLimited()
      : this._('rateLimited');
  const MaharashtraLocationSearchException.invalidResponse()
      : this._('invalidResponse');

  final String reason;
}
