import 'dart:convert';
import 'package:http/http.dart' as http;

class AirtableService {
  static const String _baseUrl = 'https://api.airtable.com/v0';
  static const String _baseId = 'appp3ZnzdIwYtZTGI';
  static const String _token = 'patjU8cD1vz8aBhYZ.33d240dfc85cb79a8e0a6d3823062a1c1ae4a408865496e9b05edadfd2fdb11e';

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      };

  // ================= SOTUVLAR BO'LIMI =================
  Future<List<Map<String, dynamic>>> getSotuvlar() async {
    final url = Uri.parse('$_baseUrl/$_baseId/Sotuvlar');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List records = data['records'];
      return records.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Sotuvlarni yuklashda xatolik: ${response.body}');
    }
  }

  Future<bool> addSotuv(Map<String, dynamic> fields) async {
    final url = Uri.parse('$_baseUrl/$_baseId/Sotuvlar');
    final body = json.encode({'fields': fields});

    final response = await http.post(url, headers: _headers, body: body);
    return response.statusCode == 200 || response.statusCode == 201;
  }

  // ================= OMBOR / TOVARLAR BO'LIMI =================
  Future<List<Map<String, dynamic>>> getTovarlar() async {
    final url = Uri.parse('$_baseUrl/$_baseId/Tovarlar');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List records = data['records'];
      return records.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Tovarlarni yuklashda xatolik: ${response.body}');
    }
  }

  Future<bool> addTovar(Map<String, dynamic> fields) async {
    final url = Uri.parse('$_baseUrl/$_baseId/Tovarlar');
    final body = json.encode({'fields': fields});

    final response = await http.post(url, headers: _headers, body: body);
    return response.statusCode == 200 || response.statusCode == 201;
  }

  // Tovar sonini yangilash (kamaytirish uchun)
  Future<bool> updateTovarSoni(String recordId, int yangiSoni) async {
    final url = Uri.parse('$_baseUrl/$_baseId/Tovarlar/$recordId');
    final body = json.encode({
      'fields': {'Soni': yangiSoni}
    });

    final response = await http.patch(url, headers: _headers, body: body);
    return response.statusCode == 200;
  }

  // ================= QARZDORLAR BO'LIMI =================
  Future<List<Map<String, dynamic>>> getQarzdorlar() async {
    final url = Uri.parse('$_baseUrl/$_baseId/Qarzdorlar');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List records = data['records'];
      return records.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Qarzdorlarni yuklashda xatolik: ${response.body}');
    }
  }

  Future<bool> addQarzdor(Map<String, dynamic> fields) async {
    final url = Uri.parse('$_baseUrl/$_baseId/Qarzdorlar');
    final body = json.encode({'fields': fields});

    final response = await http.post(url, headers: _headers, body: body);
    return response.statusCode == 200 || response.statusCode == 201;
  }

  // Qarzni o'chirish / yopish
  Future<bool> deleteQarzdor(String recordId) async {
    final url = Uri.parse('$_baseUrl/$_baseId/Qarzdorlar/$recordId');
    final response = await http.delete(url, headers: _headers);
    return response.statusCode == 200;
  }
}
