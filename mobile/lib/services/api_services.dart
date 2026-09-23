import '../core/network/api_client.dart';
import '../models/models.dart';

final _api = ApiClient.instance;

/// خدمات المصادقة (3.1)
class AuthService {
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String phone,
    required String password,
    required String role,
    String? email,
    String? wilaya,
  }) async {
    final res = await _api.post('/auth/register', {
      'fullName': fullName,
      'phone': phone,
      'password': password,
      'role': role,
      if (email != null && email.isNotEmpty) 'email': email,
      if (wilaya != null && wilaya.isNotEmpty) 'wilaya': wilaya,
    });
    return res['data'] as Map<String, dynamic>;
  }

  static Future<(String token, UserModel user)> verifyOtp(
      String phone, String code) async {
    final res =
        await _api.post('/auth/verify-otp', {'phone': phone, 'code': code});
    final data = res['data'] as Map<String, dynamic>;
    return ('${data['token']}', UserModel.fromJson(data['user']));
  }

  static Future<void> resendOtp(String phone) =>
      _api.post('/auth/resend-otp', {'phone': phone});

  static Future<(String token, UserModel user)> login(
      String identifier, String password) async {
    final res = await _api.post('/auth/login', {
      'identifier': identifier,
      'password': password,
    });
    final data = res['data'] as Map<String, dynamic>;
    return ('${data['token']}', UserModel.fromJson(data['user']));
  }

  static Future<Map<String, dynamic>> me() async {
    final res = await _api.get('/auth/me');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> forgotPassword(String phone) =>
      _api.post('/auth/forgot-password', {'phone': phone});

  static Future<void> resetPassword(
          String phone, String code, String newPassword) =>
      _api.post('/auth/reset-password', {
        'phone': phone,
        'code': code,
        'newPassword': newPassword,
      });

  static Future<void> changePassword(String current, String next) =>
      _api.patch('/auth/password', {
        'currentPassword': current,
        'newPassword': next,
      });

  static Future<void> deleteAccount(String password) =>
      _api.delete('/auth/me', {'password': password});
}

/// خدمات العروض والبحث (3.2 / 3.3 / 3.4)
class JobService {
  static Future<Map<String, dynamic>> home() async {
    final res = await _api.get('/home');
    final data = res['data'] as Map<String, dynamic>;
    return {
      'banners': (data['banners'] as List? ?? [])
          .map((e) => BannerModel.fromJson(e))
          .toList(),
      'latestOffers': (data['latestOffers'] as List? ?? [])
          .map((e) => JobOffer.fromJson(e))
          .toList(),
      'featuredOffers': (data['featuredOffers'] as List? ?? [])
          .map((e) => JobOffer.fromJson(e))
          .toList(),
      'totalOffers': (data['stats']?['totalOffers'] ?? 0) as int,
      'topWilayas': data['topWilayas'] ?? [],
    };
  }

  static Future<(List<JobOffer>, int pages)> search({
    String? q,
    String? wilaya,
    String? sector,
    String? contractType,
    int? salaryMin,
    String? educationLevel,
    String? experienceLevel,
    int? postedWithin,
    String? companyId,
    String sort = 'recent',
    int page = 1,
  }) async {
    final res = await _api.get('/jobs', query: {
      'q': q,
      'wilaya': wilaya,
      'sector': sector,
      'contractType': contractType,
      'salaryMin': salaryMin,
      'educationLevel': educationLevel,
      'experienceLevel': experienceLevel,
      'postedWithin': postedWithin,
      'company': companyId,
      'sort': sort,
      'page': page,
    });
    final data = res['data'] as Map<String, dynamic>;
    final items = (data['items'] as List? ?? [])
        .map((e) => JobOffer.fromJson(e))
        .toList();
    return (items, (data['pagination']?['pages'] ?? 1) as int);
  }

  static Future<Map<String, dynamic>> detail(String id) async {
    final res = await _api.get('/jobs/$id');
    final data = res['data'] as Map<String, dynamic>;
    return {
      'offer': JobOffer.fromJson(data['offer']),
      'isSaved': data['isSaved'] == true,
      'hasApplied': data['hasApplied'] == true,
    };
  }

  static Future<List<JobOffer>> recommended() async {
    final res = await _api.get('/jobs/recommended');
    return ((res['data']?['items'] as List?) ?? [])
        .map((e) => JobOffer.fromJson(e))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> byWilaya() async {
    final res = await _api.get('/jobs/by-wilaya');
    return ((res['data']?['items'] as List?) ?? [])
        .cast<Map<String, dynamic>>();
  }

  /// نشر عرض (3.6) — يُحفظ بحالة «قيد المراجعة»
  static Future<JobOffer> create(Map<String, dynamic> body) async {
    final res = await _api.post('/jobs', body);
    return JobOffer.fromJson(res['data']['offer']);
  }

  static Future<JobOffer> update(String id, Map<String, dynamic> body) async {
    final res = await _api.patch('/jobs/$id', body);
    return JobOffer.fromJson(res['data']['offer']);
  }

  static Future<void> changeState(String id, String action, {int? days}) =>
      _api.patch('/jobs/$id/status',
          {'action': action, if (days != null) 'days': days});

  static Future<void> remove(String id) => _api.delete('/jobs/$id');

  static Future<List<JobOffer>> mine({String? status}) async {
    final res = await _api.get('/jobs/mine/list', query: {'status': status});
    return ((res['data']?['items'] as List?) ?? [])
        .map((e) => JobOffer.fromJson(e))
        .toList();
  }
}

/// الترشّحات (3.4 / 3.7)
class ApplicationService {
  static Future<ApplicationModel> apply(String offerId,
      {String? coverLetter}) async {
    final res = await _api.post('/applications', {
      'offerId': offerId,
      if (coverLetter != null && coverLetter.isNotEmpty)
        'coverLetter': coverLetter,
    });
    return ApplicationModel.fromJson(res['data']['application']);
  }

  static Future<List<ApplicationModel>> mine({String? status}) async {
    final res = await _api.get('/applications/mine', query: {'status': status});
    return ((res['data']?['items'] as List?) ?? [])
        .map((e) => ApplicationModel.fromJson(e))
        .toList();
  }

  static Future<List<ApplicationModel>> forOffer(String offerId,
      {String? status}) async {
    final res = await _api
        .get('/applications/offer/$offerId', query: {'status': status});
    return ((res['data']?['items'] as List?) ?? [])
        .map((e) => ApplicationModel.fromJson(e))
        .toList();
  }

  static Future<ApplicationModel> detail(String id) async {
    final res = await _api.get('/applications/$id');
    return ApplicationModel.fromJson(res['data']['application']);
  }

  static Future<void> setStatus(String id, String status, {String? note}) =>
      _api.patch('/applications/$id/status', {
        'status': status,
        if (note != null && note.isNotEmpty) 'note': note,
      });

  static Future<void> withdraw(String id) => _api.delete('/applications/$id');
}

/// السيرة الذاتية (3.5)
class ProfileService {
  static Future<(ProfileModel, UserModel)> me() async {
    final res = await _api.get('/profile/me');
    final data = res['data'] as Map<String, dynamic>;
    return (
      ProfileModel.fromJson(data['profile']),
      UserModel.fromJson(data['user']),
    );
  }

  static Future<(ProfileModel, UserModel)> update(
      Map<String, dynamic> body) async {
    final res = await _api.patch('/profile/me', body);
    final data = res['data'] as Map<String, dynamic>;
    return (
      ProfileModel.fromJson(data['profile']),
      UserModel.fromJson(data['user']),
    );
  }

  static Future<ProfileModel> addExperience(Map<String, dynamic> body) async {
    final res = await _api.post('/profile/experiences', body);
    return ProfileModel.fromJson(res['data']['profile']);
  }

  static Future<ProfileModel> removeExperience(String id) async {
    final res = await _api.delete('/profile/experiences/$id');
    return ProfileModel.fromJson(res['data']['profile']);
  }

  static Future<ProfileModel> addEducation(Map<String, dynamic> body) async {
    final res = await _api.post('/profile/educations', body);
    return ProfileModel.fromJson(res['data']['profile']);
  }

  static Future<ProfileModel> removeEducation(String id) async {
    final res = await _api.delete('/profile/educations/$id');
    return ProfileModel.fromJson(res['data']['profile']);
  }

  static Future<ProfileModel> uploadCv(String filePath) async {
    final res = await _api.uploadFile('/profile/cv', 'cv', filePath);
    return ProfileModel.fromJson(res['data']['profile']);
  }

  static Future<UserModel> uploadAvatar(String filePath) async {
    final res = await _api.uploadFile('/profile/avatar', 'avatar', filePath);
    return UserModel.fromJson(res['data']['user']);
  }
}

/// المؤسسات (3.8)
class CompanyService {
  static Future<List<CompanyModel>> list({
    String? q,
    String? sector,
    String? wilaya,
    bool verifiedOnly = false,
  }) async {
    final res = await _api.get('/companies', query: {
      'q': q,
      'sector': sector,
      'wilaya': wilaya,
      if (verifiedOnly) 'verified': 'true',
    });
    return ((res['data']?['items'] as List?) ?? [])
        .map((e) => CompanyModel.fromJson(e))
        .toList();
  }

  static Future<(CompanyModel, List<JobOffer>)> detail(String id) async {
    final res = await _api.get('/companies/$id');
    final data = res['data'] as Map<String, dynamic>;
    return (
      CompanyModel.fromJson(data['company']),
      ((data['offers'] as List?) ?? [])
          .map((e) => JobOffer.fromJson(e))
          .toList(),
    );
  }

  static Future<CompanyModel> mine() async {
    final res = await _api.get('/companies/me');
    return CompanyModel.fromJson(res['data']['company']);
  }

  static Future<CompanyModel> create(Map<String, dynamic> body) async {
    final res = await _api.post('/companies', body);
    return CompanyModel.fromJson(res['data']['company']);
  }

  static Future<CompanyModel> update(Map<String, dynamic> body) async {
    final res = await _api.patch('/companies/me', body);
    return CompanyModel.fromJson(res['data']['company']);
  }

  static Future<CompanyModel> uploadLogo(String filePath) async {
    final res = await _api.uploadFile('/companies/me/logo', 'logo', filePath);
    return CompanyModel.fromJson(res['data']['company']);
  }

  static Future<Map<String, dynamic>> stats() async {
    final res = await _api.get('/companies/me/stats');
    return res['data'] as Map<String, dynamic>;
  }
}

/// المحفوظات والتنبيهات (3.3 / 3.4)
class SavedService {
  static Future<void> saveOffer(String offerId) =>
      _api.post('/saved/offers/$offerId');

  static Future<void> unsaveOffer(String offerId) =>
      _api.delete('/saved/offers/$offerId');

  static Future<List<JobOffer>> offers() async {
    final res = await _api.get('/saved/offers');
    return ((res['data']?['items'] as List?) ?? [])
        .map((e) => JobOffer.fromJson(e))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> searches() async {
    final res = await _api.get('/saved/searches');
    return ((res['data']?['items'] as List?) ?? [])
        .cast<Map<String, dynamic>>();
  }

  static Future<void> saveSearch(String label, Map<String, dynamic> criteria) =>
      _api.post('/saved/searches', {'label': label, 'criteria': criteria});

  static Future<void> toggleAlert(String id, bool enabled) =>
      _api.patch('/saved/searches/$id', {'alertEnabled': enabled});

  static Future<void> deleteSearch(String id) =>
      _api.delete('/saved/searches/$id');
}

/// المراسلة (3.7)
class MessageService {
  static Future<List<ConversationModel>> conversations() async {
    final res = await _api.get('/messages/conversations');
    return ((res['data']?['items'] as List?) ?? [])
        .map((e) => ConversationModel.fromJson(e))
        .toList();
  }

  static Future<(ConversationModel, List<MessageModel>)> messages(
      String id) async {
    final res = await _api.get('/messages/conversations/$id');
    final data = res['data'] as Map<String, dynamic>;
    return (
      ConversationModel.fromJson(data['conversation']),
      ((data['messages'] as List?) ?? [])
          .map((e) => MessageModel.fromJson(e))
          .toList(),
    );
  }

  static Future<(MessageModel, String conversationId)> send({
    String? conversationId,
    String? applicationId,
    required String body,
  }) async {
    final res = await _api.post('/messages', {
      if (conversationId != null) 'conversationId': conversationId,
      if (applicationId != null) 'applicationId': applicationId,
      'body': body,
    });
    final data = res['data'] as Map<String, dynamic>;
    return (
      MessageModel.fromJson(data['message']),
      '${data['conversationId']}'
    );
  }

  static Future<int> unreadCount() async {
    final res = await _api.get('/messages/unread-count');
    return (res['data']?['count'] ?? 0) as int;
  }
}

/// الإشعارات والبلاغات (3.4 / 3.7)
class MiscService {
  static Future<(List<NotificationModel>, int unread)> notifications() async {
    final res = await _api.get('/notifications');
    final data = res['data'] as Map<String, dynamic>;
    return (
      ((data['items'] as List?) ?? [])
          .map((e) => NotificationModel.fromJson(e))
          .toList(),
      (data['unreadCount'] ?? 0) as int,
    );
  }

  static Future<void> markRead({String? id}) =>
      _api.patch('/notifications/read', {if (id != null) 'id': id});

  static Future<void> deleteNotification(String id) =>
      _api.delete('/notifications/$id');

  static Future<void> report({
    required String targetType,
    required String targetId,
    required String reason,
    String? details,
  }) =>
      _api.post('/reports', {
        'targetType': targetType,
        'targetId': targetId,
        'reason': reason,
        if (details != null && details.isNotEmpty) 'details': details,
      });
}
