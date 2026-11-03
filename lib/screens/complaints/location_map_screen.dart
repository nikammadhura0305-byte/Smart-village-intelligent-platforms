import 'dart:async';

import '../../app_ui.dart';
import '../../language/app_language.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../services/maharashtra_location_search.dart';
import 'complaint_preview_screen.dart';

class LocationMapScreen extends StatefulWidget {
  final String category;
  final String location;
  final String description;
  final XFile? attachment;
  final bool isVideo;
  final MaharashtraLocationSearch? searchService;

  const LocationMapScreen({
    super.key,
    required this.category,
    required this.location,
    required this.description,
    required this.attachment,
    required this.isVideo,
    this.searchService,
  });

  @override
  State<LocationMapScreen> createState() => _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen> {
  static const Color green = Color(0xFF078746);
  static const Color darkGreen = Color(0xFF075B35);

  final locationController = TextEditingController();

  bool isLoading = false;
  bool hasRequestedGps = false;
  String? locationError;
  Position? currentPosition;
  bool mapTilesFailed = false;
  bool _preferVillageOnMap = true;
  int _mapRefreshCounter = 0;
  bool gpsAddressLoading = false;
  int _reverseGeocodeRequestId = 0;
  String? _lastGpsCoordinates;
  String? gpsAddress;
  String? gpsAddressError;
  MaharashtraLocationOption? selectedDistrict;
  MaharashtraLocationOption? selectedTaluka;
  MaharashtraLocationOption? selectedVillage;

  @override
  void initState() {
    super.initState();
    AppLanguage.instance.addListener(_languageChanged);
    locationController.clear();
  }

  void _languageChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppLanguage.instance.removeListener(_languageChanged);
    locationController.dispose();
    super.dispose();
  }

  String _text({
    required String mr,
    required String hi,
    required String en,
  }) {
    return AppLanguage.instance.text(mr: mr, hi: hi, en: en);
  }

  String? get _localizedLocationError => switch (locationError) {
        'serviceDisabled' => _text(
            mr: 'स्थान सेवा बंद आहे. GPS सुरू करून पुन्हा प्रयत्न करा.',
            hi: 'लोकेशन सेवा बंद है। GPS चालू करके फिर प्रयास करें।',
            en: 'Location services are off. Enable GPS and try again.',
          ),
        'permissionDenied' => _text(
            mr: 'स्थान परवानगी नाकारली आहे. अॅप किंवा ब्राउझर सेटिंग्जमध्ये परवानगी द्या.',
            hi: 'लोकेशन अनुमति अस्वीकार की गई। ऐप या ब्राउज़र सेटिंग्स में अनुमति दें।',
            en: 'Location permission was denied. Allow it in app or browser settings.',
          ),
        'permissionDeniedForever' => _text(
            mr: 'स्थान परवानगी कायमची बंद आहे. उपकरणाच्या सेटिंग्जमधून ती सुरू करा.',
            hi: 'लोकेशन अनुमति स्थायी रूप से बंद है। डिवाइस सेटिंग्स में इसे चालू करें।',
            en: 'Location permission is permanently denied. Enable it in device settings.',
          ),
        'timeout' => _text(
            mr: 'स्थान मिळवण्यासाठी वेळ संपला. GPS सुरू आहे का तपासून पुन्हा प्रयत्न करा.',
            hi: 'स्थान प्राप्त करने का समय समाप्त हुआ। GPS जाँचकर फिर प्रयास करें।',
            en: 'Getting the location timed out. Check GPS and try again.',
          ),
        'unavailable' => _text(
            mr: 'सध्याचे स्थान मिळू शकले नाही. GPS सुरू आहे का तपासून पुन्हा प्रयत्न करा.',
            hi: 'वर्तमान स्थान नहीं मिल सका। GPS जाँचकर फिर प्रयास करें।',
            en: 'Could not get the current location. Check GPS and try again.',
          ),
        _ => null,
      };

  String _selectedVillageLocation(
    MaharashtraLocationOption village,
    MaharashtraLocationOption taluka,
    MaharashtraLocationOption district,
  ) =>
      '${village.name}, ${taluka.name}, ${district.name}, Maharashtra';

  String? _localizedSearchError(String? reason) => switch (reason) {
        'timeout' => _text(
            mr: 'स्थान शोधण्याची विनंती वेळेत पूर्ण झाली नाही. पुन्हा प्रयत्न करा.',
            hi: 'स्थान खोजने का अनुरोध समय पर पूरा नहीं हुआ। फिर प्रयास करें।',
            en: 'The location search timed out. Please try again.',
          ),
        'rateLimited' => _text(
            mr: 'नकाशा सेवा व्यस्त आहे. काही वेळाने पुन्हा प्रयत्न करा.',
            hi: 'मानचित्र सेवा व्यस्त है। थोड़ी देर बाद फिर प्रयास करें।',
            en: 'The map service is busy. Please try again shortly.',
          ),
        'invalidResponse' => _text(
            mr: 'स्थान सेवा वैध परिणाम देऊ शकली नाही.',
            hi: 'स्थान सेवा वैध परिणाम नहीं दे सकी।',
            en: 'The location service returned an invalid response.',
          ),
        'unavailable' => _text(
            mr: 'स्थान शोधता आले नाही. इंटरनेट जोडणी तपासा.',
            hi: 'स्थान खोजा नहीं जा सका। इंटरनेट कनेक्शन जाँचें।',
            en: 'Could not search for locations. Check your internet connection.',
          ),
        _ => null,
      };

  Future<void> _searchLocation(MaharashtraLocationLevel level) async {
    final initialValue =
        level == MaharashtraLocationLevel.village ? widget.location : '';
    final result = await showDialog<MaharashtraLocationOption>(
      context: context,
      builder: (context) => _LocationSearchDialog(
        level: level,
        initialValue: initialValue,
        district: selectedDistrict?.name,
        taluka: selectedTaluka?.name,
        languageCode: AppLanguage.instance.locale.languageCode,
        searchService:
            widget.searchService ?? MaharashtraLocationSearch.instance,
        localizedError: _localizedSearchError,
        text: _text,
      ),
    );
    if (!mounted || result == null) return;

    setState(() {
      switch (level) {
        case MaharashtraLocationLevel.district:
          selectedDistrict = result;
          selectedTaluka = null;
          selectedVillage = null;
        case MaharashtraLocationLevel.taluka:
          selectedTaluka = result;
          selectedVillage = null;
        case MaharashtraLocationLevel.village:
          selectedVillage = result;
      }
      final village = selectedVillage;
      final taluka = selectedTaluka;
      final district = selectedDistrict;
      locationController.text =
          village != null && taluka != null && district != null
              ? _selectedVillageLocation(village, taluka, district)
              : '';
      mapTilesFailed = false;
      if (level == MaharashtraLocationLevel.village) {
        _preferVillageOnMap = true;
      }
    });
  }

  Future<void> getCurrentLocation() async {
    if (!mounted || isLoading) return;

    setState(() {
      isLoading = true;
      hasRequestedGps = true;
      locationError = null;
      currentPosition = null;
      gpsAddress = null;
      gpsAddressError = null;
      gpsAddressLoading = false;
      _reverseGeocodeRequestId++;
      mapTilesFailed = false;
      _lastGpsCoordinates = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (mounted) setState(() => locationError = 'serviceDisabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => locationError = 'permissionDenied');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => locationError = 'permissionDeniedForever');
        }
        return;
      }

      if (permission == LocationPermission.unableToDetermine) {
        if (mounted) setState(() => locationError = 'unavailable');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 25),
        ),
      );

      if (!mounted) return;

      setState(() {
        currentPosition = position;
        _preferVillageOnMap = false;
        mapTilesFailed = false;
        _lastGpsCoordinates =
            '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      });
      unawaited(_loadGpsAddress(position));
    } on TimeoutException {
      if (!mounted) return;
      setState(() => locationError = 'timeout');
    } on LocationServiceDisabledException {
      if (!mounted) return;
      setState(() => locationError = 'serviceDisabled');
    } on PermissionDeniedException {
      if (!mounted) return;
      setState(() => locationError = 'permissionDenied');
    } catch (error, stackTrace) {
      debugPrint('Could not fetch current location: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => locationError = 'unavailable');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadGpsAddress(Position position) async {
    final requestId = ++_reverseGeocodeRequestId;
    setState(() => gpsAddressLoading = true);
    try {
      final address = await MaharashtraLocationSearch.instance.reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
        languageCode: AppLanguage.instance.locale.languageCode,
      );
      if (!mounted || requestId != _reverseGeocodeRequestId) return;
      setState(() {
        gpsAddress = address;
        gpsAddressError = address == null ? 'unavailable' : null;
      });
    } on MaharashtraLocationSearchException catch (error) {
      if (!mounted || requestId != _reverseGeocodeRequestId) return;
      setState(() => gpsAddressError = error.reason);
    } catch (error, stackTrace) {
      debugPrint('Could not resolve current GPS address: $error\n$stackTrace');
      if (!mounted || requestId != _reverseGeocodeRequestId) return;
      setState(() => gpsAddressError = 'unavailable');
    } finally {
      if (mounted && requestId == _reverseGeocodeRequestId) {
        setState(() => gpsAddressLoading = false);
      }
    }
  }

  void continueToPreview() {
    final village = selectedVillage;
    final taluka = selectedTaluka;
    final district = selectedDistrict;

    if (village == null || taluka == null || district == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              mr: 'कृपया महाराष्ट्रातील जिल्हा, तालुका आणि गाव निवडा.',
              hi: 'कृपया महाराष्ट्र में जिला, तालुका और गाँव चुनें।',
              en: 'Select a Maharashtra district, taluka, and village.',
            ),
          ),
        ),
      );
      return;
    }

    final location = _selectedVillageLocation(village, taluka, district);
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ComplaintPreviewScreen(
          category: widget.category,
          location: location,
          description: widget.description,
          attachment: widget.attachment,
          isVideo: widget.isVideo,
          liveGpsCoordinates: _lastGpsCoordinates,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F4),
      appBar: AppBar(
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        title: Text(
          _text(
            mr: 'GPS स्थान',
            hi: 'GPS स्थान',
            en: 'GPS Location',
          ),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    darkGreen,
                    Color(0xFF20B66A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: Colors.white,
                    size: 66,
                  ),
                  SizedBox(height: 12),
                  Text(
                    _text(
                      mr: 'तुमचे ठिकाण निश्चित करा',
                      hi: 'अपना स्थान तय करें',
                      en: 'Confirm your location',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _text(
                      mr: 'जिल्हा, तालुका आणि गाव निवडा. प्रत्यक्ष GPS स्थान हवे असल्यास ते वेगळे मिळवा.',
                      hi: 'जिला, तालुका और गाँव चुनें। वास्तविक GPS स्थान चाहिए तो उसे अलग से प्राप्त करें।',
                      en: 'Select a district, taluka, and village. Request actual device GPS separately if needed.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _locationSelectionCard(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFDCE9DF),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.gps_fixed_rounded,
                        color: green,
                        size: 26,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _text(
                            mr: 'सध्याचे GPS स्थान',
                            hi: 'वर्तमान GPS स्थान',
                            en: 'Current GPS location',
                          ),
                          style: TextStyle(
                            color: darkGreen,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: _text(
                          mr: 'स्थान पुन्हा मिळवा',
                          hi: 'स्थान फिर से प्राप्त करें',
                          en: 'Refresh location',
                        ),
                        onPressed: isLoading ? null : getCurrentLocation,
                        icon: const Icon(Icons.refresh_rounded, color: green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : getCurrentLocation,
                      icon: const Icon(Icons.my_location_rounded),
                      label: Text(
                        _text(
                          mr: 'माझे सध्याचे स्थान वापरा',
                          hi: 'मेरी वर्तमान लोकेशन इस्तेमाल करें',
                          en: 'Use My Current Location',
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: green,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: green),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isLoading) ...[
                    const Center(
                      child: CircularProgressIndicator(
                        color: green,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        _text(
                          mr: 'GPS स्थान शोधत आहे...',
                          hi: 'GPS स्थान खोज रहे हैं...',
                          en: 'Finding GPS location...',
                        ),
                        style: TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ] else if (currentPosition != null) ...[
                    if (locationError == null)
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _text(
                                mr: 'GPS स्थान मिळाले.',
                                hi: 'GPS स्थान मिल गया।',
                                en: 'GPS location received.',
                              ),
                              style: const TextStyle(
                                color: green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        _localizedLocationError!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    const SizedBox(height: 12),
                    _coordinateRow(
                      _text(mr: 'अक्षांश', hi: 'अक्षांश', en: 'Latitude'),
                      currentPosition!.latitude.toStringAsFixed(6),
                    ),
                    const SizedBox(height: 8),
                    _coordinateRow(
                      _text(mr: 'रेखांश', hi: 'देशांतर', en: 'Longitude'),
                      currentPosition!.longitude.toStringAsFixed(6),
                    ),
                    if (gpsAddress != null) ...[
                      const SizedBox(height: 8),
                      _coordinateRow(
                        _text(
                            mr: 'जवळचा पत्ता',
                            hi: 'निकटतम पता',
                            en: 'Nearby address'),
                        gpsAddress!,
                      ),
                    ] else if (gpsAddressLoading) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _text(
                              mr: 'जवळचा पत्ता शोधत आहे...',
                              hi: 'निकटतम पता खोज रहे हैं...',
                              en: 'Resolving nearby address...',
                            ),
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ] else if (gpsAddressError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _localizedSearchError(gpsAddressError) ??
                            _text(
                              mr: 'पत्त्याची माहिती उपलब्ध नाही.',
                              hi: 'पते की जानकारी उपलब्ध नहीं है।',
                              en: 'Address information is unavailable.',
                            ),
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ] else if (!hasRequestedGps) ...[
                    Text(
                      _text(
                        mr: 'गावाचे स्थान निवडल्यानंतर, हवे असल्यास प्रत्यक्ष GPS मिळवण्यासाठी वरील बटण दाबा.',
                        hi: 'गाँव का स्थान चुनने के बाद, वास्तविक GPS पाने के लिए ऊपर दिया बटन दबाएँ।',
                        en: 'After selecting the village, use the button above if you also want the device’s actual GPS location.',
                      ),
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ] else ...[
                    const Icon(
                      Icons.location_searching_rounded,
                      color: Colors.orange,
                      size: 35,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _localizedLocationError ??
                          _text(
                            mr: 'GPS स्थान उपलब्ध नाही.',
                            hi: 'GPS स्थान उपलब्ध नहीं है।',
                            en: 'GPS location is unavailable.',
                          ),
                      style: const TextStyle(
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: getCurrentLocation,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(
                        _text(
                          mr: 'पुन्हा प्रयत्न करा',
                          hi: 'फिर से प्रयास करें',
                          en: 'Try again',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selectedVillage != null || currentPosition != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _text(
                        mr: 'गाव आणि सध्याचे स्थान',
                        hi: 'गाँव और वर्तमान स्थान',
                        en: 'Village and current location',
                      ),
                      style: const TextStyle(
                        color: darkGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: _text(
                      mr: 'नकाशा पुन्हा लोड करा',
                      hi: 'मानचित्र फिर से लोड करें',
                      en: 'Refresh map',
                    ),
                    onPressed: () {
                      setState(() {
                        _preferVillageOnMap = selectedVillage != null;
                        _mapRefreshCounter++;
                        mapTilesFailed = false;
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded, color: green),
                  ),
                ],
              ),
              SizedBox(
                height: 260,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: FlutterMap(
                    key: ValueKey(
                      '${selectedVillage?.id}|${currentPosition?.latitude},${currentPosition?.longitude}|$_mapRefreshCounter',
                    ),
                    options: MapOptions(
                      initialCenter: _preferVillageOnMap
                          ? selectedVillage?.point ??
                              LatLng(
                                currentPosition!.latitude,
                                currentPosition!.longitude,
                              )
                          : currentPosition == null
                              ? selectedVillage!.point
                              : LatLng(
                                  currentPosition!.latitude,
                                  currentPosition!.longitude,
                                ),
                      initialZoom:
                          currentPosition != null && !_preferVillageOnMap
                              ? 15
                              : 13,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.gramsaksham_app',
                        errorTileCallback: (_, __, ___) {
                          if (!mounted || mapTilesFailed) return;
                          setState(() => mapTilesFailed = true);
                        },
                      ),
                      MarkerLayer(
                        markers: [
                          if (selectedVillage case final village?)
                            Marker(
                              point: village.point,
                              width: 48,
                              height: 48,
                              child: const Icon(
                                Icons.location_pin,
                                color: green,
                                size: 44,
                              ),
                            ),
                          if (currentPosition case final position?)
                            Marker(
                              point: LatLng(
                                position.latitude,
                                position.longitude,
                              ),
                              width: 48,
                              height: 48,
                              child: const Icon(
                                Icons.person_pin_circle_rounded,
                                color: Colors.red,
                                size: 44,
                              ),
                            ),
                        ],
                      ),
                      RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution(
                            '© OpenStreetMap contributors',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (selectedVillage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _text(
                    mr: 'हिरवा मार्कर: निवडलेले गाव. लाल मार्कर: तुमचे प्रत्यक्ष GPS स्थान.',
                    hi: 'हरा मार्कर: चुना हुआ गाँव। लाल मार्कर: आपका वास्तविक GPS स्थान।',
                    en: 'Green marker: selected village. Red marker: your actual GPS location.',
                  ),
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              if (mapTilesFailed)
                Text(
                  _text(
                    mr: 'नकाशा लोड झाला नाही. इंटरनेट तपासा; निवडलेल्या गावाची माहिती आणि उपलब्ध GPS निर्देशांक दिसत राहतील.',
                    hi: 'मानचित्र लोड नहीं हुआ। इंटरनेट जाँचें; चुने हुए गाँव की जानकारी और उपलब्ध GPS निर्देशांक दिखते रहेंगे।',
                    en: 'The map could not load. Check your internet connection; the selected village and any available GPS coordinates remain visible.',
                  ),
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
            ],
            const SizedBox(height: 20),
            Text(
              _text(
                mr: 'निवडलेले तक्रारीचे गाव',
                hi: 'चुना हुआ शिकायत गाँव',
                en: 'Selected complaint village',
              ),
              style: TextStyle(
                color: darkGreen,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: locationController,
              maxLines: 2,
              readOnly: true,
              onTap: () => _searchLocation(MaharashtraLocationLevel.village),
              decoration: InputDecoration(
                hintText: _text(
                  mr: 'जिल्हा, तालुका आणि गाव निवडा',
                  hi: 'जिला, तालुका और गाँव चुनें',
                  en: 'Select a district, taluka, and village',
                ),
                prefixIcon: const Icon(
                  Icons.place_rounded,
                  color: green,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: Color(0xFFDCE9DF),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _text(
                mr: 'निवडलेले गाव तक्रारीचे ठिकाण आहे. GPS स्थान वेगळे दाखवले जाते.',
                hi: 'चुना हुआ गाँव शिकायत का स्थान है। GPS स्थान अलग दिखाया जाता है।',
                en: 'The selected village is the complaint location. GPS is shown separately.',
              ),
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: continueToPreview,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  _text(
                    mr: 'पुढे जा — तक्रार तपासा',
                    hi: 'आगे बढ़ें — शिकायत जाँचें',
                    en: 'Continue — review complaint',
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationSelectionCard() {
    final district = selectedDistrict;
    final taluka = selectedTaluka;
    final village = selectedVillage;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE9DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _text(
              mr: 'महाराष्ट्रातील गाव निवडा',
              hi: 'महाराष्ट्र में गाँव चुनें',
              en: 'Select a village in Maharashtra',
            ),
            style: const TextStyle(
              color: darkGreen,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _locationPickerTile(
            label: _text(mr: 'राज्य', hi: 'राज्य', en: 'State'),
            value: _text(
              mr: 'महाराष्ट्र',
              hi: 'महाराष्ट्र',
              en: 'Maharashtra',
            ),
            enabled: false,
            onPressed: null,
          ),
          const SizedBox(height: 8),
          _locationPickerTile(
            label: _text(mr: 'जिल्हा', hi: 'जिला', en: 'District'),
            value: district?.name,
            enabled: true,
            onPressed: () => _searchLocation(MaharashtraLocationLevel.district),
          ),
          const SizedBox(height: 8),
          _locationPickerTile(
            label: _text(mr: 'तालुका', hi: 'तालुका', en: 'Taluka'),
            value: taluka?.name,
            enabled: district != null,
            onPressed: district == null
                ? null
                : () => _searchLocation(MaharashtraLocationLevel.taluka),
          ),
          const SizedBox(height: 8),
          _locationPickerTile(
            label: _text(mr: 'गाव', hi: 'गाँव', en: 'Village'),
            value: village?.name,
            enabled: taluka != null,
            onPressed: taluka == null
                ? null
                : () => _searchLocation(MaharashtraLocationLevel.village),
          ),
          if (village != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                village.displayName,
                style: const TextStyle(
                  color: darkGreen,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            _text(
              mr: 'परिणाम OpenStreetMap मधून शोधले जातात; ही संपूर्ण अधिकृत गाव-यादी नाही.',
              hi: 'परिणाम OpenStreetMap से खोजे जाते हैं; यह पूरी आधिकारिक गाँव-सूची नहीं है।',
              en: 'Results are searched in OpenStreetMap; this is not a complete official village register.',
            ),
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationPickerTile({
    required String label,
    required String? value,
    required bool enabled,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        isEmpty: value == null,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Icon(
            enabled ? Icons.search_rounded : Icons.lock_outline_rounded,
            color: enabled ? green : Colors.black38,
          ),
          filled: true,
          fillColor: enabled ? Colors.white : const Color(0xFFF4F6F4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDCE9DF)),
          ),
        ),
        child: Text(
          value ??
              _text(
                mr: 'शोधण्यासाठी टॅप करा',
                hi: 'खोजने के लिए टैप करें',
                en: enabled
                    ? 'Tap to search'
                    : 'Select the previous level first',
              ),
          style: TextStyle(
            color: value == null ? Colors.black54 : darkGreen,
            fontWeight: value == null ? FontWeight.normal : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _coordinateRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 85,
          child: Text(
            '$label:',
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(
              color: darkGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationSearchDialog extends StatefulWidget {
  const _LocationSearchDialog({
    required this.level,
    required this.initialValue,
    required this.district,
    required this.taluka,
    required this.languageCode,
    required this.searchService,
    required this.localizedError,
    required this.text,
  });

  final MaharashtraLocationLevel level;
  final String initialValue;
  final String? district;
  final String? taluka;
  final String languageCode;
  final MaharashtraLocationSearch searchService;
  final String? Function(String?) localizedError;
  final String Function({
    required String mr,
    required String hi,
    required String en,
  }) text;

  @override
  State<_LocationSearchDialog> createState() => _LocationSearchDialogState();
}

class _LocationSearchDialogState extends State<_LocationSearchDialog> {
  late final TextEditingController _queryController =
      TextEditingController(text: widget.initialValue);
  List<MaharashtraLocationOption> _results = const [];
  String? _error;
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  String get _title => switch (widget.level) {
        MaharashtraLocationLevel.district => widget.text(
            mr: 'जिल्हा शोधा', hi: 'जिला खोजें', en: 'Search district'),
        MaharashtraLocationLevel.taluka => widget.text(
            mr: 'तालुका शोधा', hi: 'तालुका खोजें', en: 'Search taluka'),
        MaharashtraLocationLevel.village =>
          widget.text(mr: 'गाव शोधा', hi: 'गाँव खोजें', en: 'Search village'),
      };

  String get _hint => switch (widget.level) {
        MaharashtraLocationLevel.district => widget.text(
            mr: 'जिल्ह्याचे नाव लिहा',
            hi: 'जिले का नाम लिखें',
            en: 'Enter a district name',
          ),
        MaharashtraLocationLevel.taluka => widget.text(
            mr: 'तालुक्याचे नाव लिहा',
            hi: 'तालुका का नाम लिखें',
            en: 'Enter a taluka name',
          ),
        MaharashtraLocationLevel.village => widget.text(
            mr: 'गावाचे नाव लिहा',
            hi: 'गाँव का नाम लिखें',
            en: 'Enter a village name',
          ),
      };

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      setState(() => _error = widget.text(
            mr: 'शोधण्यासाठी नाव लिहा.',
            hi: 'खोजने के लिए नाम लिखें।',
            en: 'Enter a name to search.',
          ));
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _error = null;
      _results = const [];
    });
    try {
      final results = await widget.searchService.search(
        level: widget.level,
        query: query,
        district: widget.district,
        taluka: widget.taluka,
        languageCode: widget.languageCode,
      );
      if (!mounted) return;
      setState(() => _results = results);
    } on MaharashtraLocationSearchException catch (error) {
      if (!mounted) return;
      setState(() => _error = widget.localizedError(error.reason));
    } catch (error, stackTrace) {
      debugPrint('Maharashtra location search failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _error = widget.localizedError('unavailable'));
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(_title),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _queryController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: _hint,
                prefixIcon: const Icon(Icons.search_rounded),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSearching ? null : _search,
                icon: const Icon(Icons.search_rounded),
                label: Text(
                  widget.text(
                    mr: 'शोधा',
                    hi: 'खोजें',
                    en: 'Search',
                  ),
                ),
              ),
            ),
            if (_isSearching) ...[
              const SizedBox(height: 14),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 8),
            Text(
              widget.text(
                mr: 'शोध परिणाम © OpenStreetMap contributors',
                hi: 'खोज परिणाम © OpenStreetMap contributors',
                en: 'Search results © OpenStreetMap contributors',
              ),
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 11,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
            if (_hasSearched &&
                !_isSearching &&
                _error == null &&
                _results.isEmpty) ...[
              const SizedBox(height: 14),
              Text(
                widget.text(
                  mr: 'जुळणारे परिणाम सापडले नाहीत. दुसरे नाव वापरून पाहा.',
                  hi: 'कोई मिलते-जुलते परिणाम नहीं मिले। दूसरा नाम आज़माएँ।',
                  en: 'No matching results. Try another spelling or name.',
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 300,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final option = _results[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(option.name),
                      subtitle: Text(option.displayName),
                      onTap: () => Navigator.pop(context, option),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            widget.text(
              mr: 'रद्द करा',
              hi: 'रद्द करें',
              en: 'Cancel',
            ),
          ),
        ),
      ],
    );
  }
}
