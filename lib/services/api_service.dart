import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graduation/storage_helper.dart';

final SecureStorage = FlutterSecureStorage();

class ApiService {
  static const String baseUrl = "http://192.168.1.109:8000/api";

  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({'email': email, 'password': password}),
      );

      print(" ${response.body}");
      final body = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = body['data']?['token'];
        final user = body['data']?['user'];

        if (token != null) {
          await SecureStorage.delete(key: 'token');
          await SecureStorage.write(key: 'token', value: token);
        }

        // ✅ هنا مباشرة نحفظ بيانات المستخدم
        if (user is Map) {
          await StorageHelper.saveUserData(
            user['name'] ?? '',
            user['email'] ?? '',
            user['phone'] ?? user['mobile'] ?? user['tel'] ?? '',
          );
        }

        return {"success": true, "data": body};
      } else {
        return {"success": false, "data": body};
      }
    } catch (e) {
      return {"success": false, "data": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'password_confirmation': confirmPassword,
        }),
      );

      print("(Register): ${response.body}");
      final body = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = body['data']?['token'];
        if (token != null) {
          await SecureStorage.delete(key: 'token');
          await SecureStorage.write(key: 'token', value: token);
          print("Token Saved ");
        }
        return {"success": true, "data": body};
      } else {
        return {"success": false, "data": body};
      }
    } catch (e) {
      return {"success": false, "data": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> sendOtp({required String email}) async {
    try {
      String? token = await SecureStorage.read(key: 'token');

      final response = await http.post(
        Uri.parse('$baseUrl/send-otp'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {"success": true, "data": json.decode(response.body)};
      } else {
        return {"success": false, "data": json.decode(response.body)};
      }
    } catch (e) {
      return {"success": false, "data": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String code,
  }) async {
    try {
      String? token = await SecureStorage.read(key: 'token');

      final response = await http.post(
        Uri.parse('$baseUrl/verify-otp'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'email': email, 'code': code}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {"success": true, "data": json.decode(response.body)};
      } else {
        return {"success": false, "data": json.decode(response.body)};
      }
    } catch (e) {
      return {"success": false, "data": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      String? token = await SecureStorage.read(key: 'token');

      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {"success": true, "data": json.decode(response.body)};
      } else {
        return {"success": false, "data": json.decode(response.body)};
      }
    } catch (e) {
      return {"success": false, "data": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    String? phone,
  }) async {
    try {
      String? token = await SecureStorage.read(key: 'token');

      if (token == null) {
        return {"success": false, "data": "Authorization token not found"};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/update-profile'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'email': email,
          if (phone != null) 'phone': phone,
        }),
      );

      dynamic parsedBody;
      try {
        parsedBody = json.decode(response.body);
      } catch (_) {
        parsedBody = response.body;
      }

      if (response.statusCode == 200) {
        return {"success": true, "data": parsedBody};
      } else {
        return {
          "success": false,
          "statusCode": response.statusCode,
          "data": parsedBody,
        };
      }
    } catch (e) {
      return {"success": false, "data": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await SecureStorage.read(key: 'token');
      if (token == null) {
        return {
          "success": false,
          "statusCode": 401,
          "data": {"message": "Authorization token not found"},
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final decoded =
          response.body.isNotEmpty ? json.decode(response.body) : {};
      Map<String, dynamic> obj = decoded is Map<String, dynamic> ? decoded : {};
      final dataNode = (obj['data'] is Map) ? obj['data'] : obj;
      final userNode = (dataNode['user'] is Map) ? dataNode['user'] : dataNode;

      final normalized = {
        "id": userNode["id"],
        "name": userNode["name"],
        "email": userNode["email"],
        "phone": userNode["phone"] ?? userNode["mobile"] ?? userNode["tel"],
        "raw": obj, // للديبغ إن احتجت
      };

      return {
        "success": response.statusCode == 200,
        "statusCode": response.statusCode,
        "data": normalized,
      };
    } catch (e) {
      return {
        "success": false,
        "statusCode": 0,
        "data": {"message": e.toString()},
      };
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      final token = await SecureStorage.read(key: 'token');
      if (token == null) {
        return {
          "success": false,
          "statusCode": 401,
          "data": {"message": "No token found"},
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final body = response.body.isNotEmpty ? json.decode(response.body) : {};

      if (response.statusCode == 200) {}

      return {
        "success": response.statusCode == 200,
        "statusCode": response.statusCode,
        "data": body,
      };
    } catch (e) {
      return {
        "success": false,
        "statusCode": 0,
        "data": {"message": e.toString()},
      };
    }
  }
}
