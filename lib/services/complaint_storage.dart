
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ComplaintStorage {
  static const String _storageKey = 'gramsaksham_complaints';

  static Future<List<Map<String, dynamic>>> getComplaints() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(_storageKey);

    if (savedData == null || savedData.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(savedData) as List<dynamic>;

    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static Future<Map<String, dynamic>> saveComplaint({
    required String category,
    required String location,
    required String description,
  }) async {
    final complaints = await getComplaints();
    final now = DateTime.now();

    final complaint = <String, dynamic>{
      'id': 'GS${now.millisecondsSinceEpoch}',
      'category': category,
      'location': location.trim(),
      'description': description.trim(),
      'date': now.toIso8601String(),
      'status': 'Pending',
    };

    complaints.insert(0, complaint);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(complaints));

    return complaint;
  }
}
