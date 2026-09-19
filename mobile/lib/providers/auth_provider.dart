import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/models.dart';
import '../services/api_services.dart';
import '../services/socket_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  ProfileModel? _profile;
  CompanyModel? _company;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  ProfileModel? get profile => _profile;
  CompanyModel? get company => _company;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isSeeker => _user?.isSeeker ?? false;
  bool get isCompany => _user?.isCompany ?? false;

  /// يُستدعى عند إقلاع التطبيق: يستعيد الجلسة المحفوظة إن وُجدت
  Future<void> bootstrap() async {
    await ApiClient.instance.loadToken();

    if (ApiClient.instance.token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      await _loadMe();
      _status = AuthStatus.authenticated;
      SocketService.instance.connect(ApiClient.instance.token!);
    } catch (_) {
      // الرمز منتهٍ أو غير صالح
      await ApiClient.instance.setToken(null);
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> _loadMe() async {
    final data = await AuthService.me();
    _user = UserModel.fromJson(data['user']);
    _profile = data['profile'] != null ? ProfileModel.fromJson(data['profile']) : null;
    _company = data['company'] != null ? CompanyModel.fromJson(data['company']) : null;
  }

  Future<void> login(String identifier, String password) async {
    final (token, user) = await AuthService.login(identifier, password);
    await ApiClient.instance.setToken(token);
    _user = user;
    await _loadMe();
    _status = AuthStatus.authenticated;
    SocketService.instance.connect(token);
    notifyListeners();
  }

  /// يُعيد رمز OTP في وضع التطوير لتسهيل الاختبار
  Future<String?> register({
    required String fullName,
    required String phone,
    required String password,
    required String role,
    String? email,
    String? wilaya,
  }) async {
    final data = await AuthService.register(
      fullName: fullName,
      phone: phone,
      password: password,
      role: role,
      email: email,
      wilaya: wilaya,
    );
    return data['devOtp'] as String?;
  }

  Future<void> verifyOtp(String phone, String code) async {
    final (token, user) = await AuthService.verifyOtp(phone, code);
    await ApiClient.instance.setToken(token);
    _user = user;
    await _loadMe();
    _status = AuthStatus.authenticated;
    SocketService.instance.connect(token);
    notifyListeners();
  }

  Future<void> logout() async {
    SocketService.instance.disconnect();
    await ApiClient.instance.setToken(null);
    _user = null;
    _profile = null;
    _company = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (!isAuthenticated) return;
    await _loadMe();
    notifyListeners();
  }

  void setProfile(ProfileModel p) {
    _profile = p;
    notifyListeners();
  }

  void setUser(UserModel u) {
    _user = u;
    notifyListeners();
  }

  void setCompany(CompanyModel c) {
    _company = c;
    notifyListeners();
  }
}
