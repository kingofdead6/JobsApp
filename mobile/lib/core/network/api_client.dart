import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// خطأ قادم من الـ API برسالة عربية جاهزة للعرض
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic details;

  ApiException(this.statusCode, this.message, [this.details]);

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  /// عنوان الخادم المنشور على Render.
  /// للتطوير محليًا مرّر العنوان عند التشغيل:
  ///   flutter run --dart-define=API_URL=http://10.0.2.2:5000
  /// (10.0.2.2 هو عنوان جهاز المضيف من داخل محاكي Android)
  static const String _rawBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://jobsapp-5pvi.onrender.com',
  );

  /// يُزال الشرطة المائلة الأخيرة حتى لا ينتج `//api` عند التركيب
  static String get baseUrl => _rawBaseUrl.endsWith('/')
      ? _rawBaseUrl.substring(0, _rawBaseUrl.length - 1)
      : _rawBaseUrl;

  static String get apiUrl => '$baseUrl/api';

  String? _token;
  String? get token => _token;

  static const _tokenKey = 'auth_token';

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  Future<void> setToken(String? value) async {
    _token = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, value);
    }
  }

  Map<String, String> _headers({bool json = true}) => {
        if (json) 'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final cleaned = query?.map((k, v) => MapEntry(k, v?.toString()))
      ?..removeWhere((_, v) => v == null || v.isEmpty);
    return Uri.parse('$apiUrl$path').replace(
      queryParameters: (cleaned?.isEmpty ?? true) ? null : cleaned!.cast<String, String>(),
    );
  }

  Map<String, dynamic> _decode(http.Response res) {
    late final Map<String, dynamic> body;
    try {
      body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(res.statusCode, 'تعذّرت قراءة ردّ الخادم');
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    throw ApiException(
      res.statusCode,
      (body['message'] as String?) ?? 'حدث خطأ غير متوقّع',
      body['details'],
    );
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on SocketException {
      throw ApiException(0, 'تعذّر الاتصال بالخادم، تحقّق من اتصالك بالإنترنت');
    } on HttpException {
      throw ApiException(0, 'تعذّر الاتصال بالخادم');
    }
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      _guard(() async => _decode(await http.get(_uri(path, query), headers: _headers())));

  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) =>
      _guard(() async => _decode(await http.post(
            _uri(path),
            headers: _headers(),
            body: body == null ? null : jsonEncode(body),
          )));

  Future<Map<String, dynamic>> patch(String path, [Map<String, dynamic>? body]) =>
      _guard(() async => _decode(await http.patch(
            _uri(path),
            headers: _headers(),
            body: body == null ? null : jsonEncode(body),
          )));

  Future<Map<String, dynamic>> delete(String path, [Map<String, dynamic>? body]) =>
      _guard(() async => _decode(await http.delete(
            _uri(path),
            headers: _headers(),
            body: body == null ? null : jsonEncode(body),
          )));

  /// رفع ملف (سيرة ذاتية، شعار، صورة شخصية)
  Future<Map<String, dynamic>> uploadFile(
    String path,
    String fieldName,
    String filePath,
  ) =>
      _guard(() async {
        final request = http.MultipartRequest('POST', _uri(path))
          ..headers.addAll(_headers(json: false))
          ..files.add(await http.MultipartFile.fromPath(fieldName, filePath));

        final streamed = await request.send();
        return _decode(await http.Response.fromStream(streamed));
      });

  /// روابط Cloudinary تصل مطلقة (https://…) فتُعاد كما هي.
  /// أمّا مسارات التخزين المحلي (/uploads/…) فيُضاف إليها عنوان الخادم.
  static String? fileUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '$baseUrl$path';
  }
}
