import '../core/network/api_client.dart';

/// تحويل آمن للأرقام القادمة من JSON (قد تصل كـ int أو double أو String)
int? _asInt(dynamic v) =>
    v == null ? null : (v is int ? v : (v is double ? v.toInt() : int.tryParse('$v')));

DateTime? _asDate(dynamic v) => v == null ? null : DateTime.tryParse('$v')?.toLocal();

List<String> _asStrings(dynamic v) =>
    v is List ? v.map((e) => '$e').toList() : const <String>[];

class UserModel {
  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String role;
  final String? wilaya;
  final String? avatar;
  final bool phoneVerified;
  final String status;

  UserModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.role,
    this.email,
    this.wilaya,
    this.avatar,
    this.phoneVerified = false,
    this.status = 'active',
  });

  bool get isSeeker => role == 'seeker';
  bool get isCompany => role == 'company';
  bool get isAdmin => role == 'admin';

  String? get avatarUrl => ApiClient.fileUrl(avatar);

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: '${j['_id']}',
        fullName: '${j['fullName'] ?? ''}',
        phone: '${j['phone'] ?? ''}',
        email: j['email'] as String?,
        role: '${j['role'] ?? 'seeker'}',
        wilaya: j['wilaya'] as String?,
        avatar: j['avatar'] as String?,
        phoneVerified: j['phoneVerified'] == true,
        status: '${j['status'] ?? 'active'}',
      );
}

class CompanyModel {
  final String id;
  final String name;
  final String? logo;
  final String? sector;
  final String? description;
  final String? wilaya;
  final String verificationStatus;
  final String? website;
  final String? employeesRange;
  final int activeOffers;

  CompanyModel({
    required this.id,
    required this.name,
    this.logo,
    this.sector,
    this.description,
    this.wilaya,
    this.verificationStatus = 'unverified',
    this.website,
    this.employeesRange,
    this.activeOffers = 0,
  });

  bool get isVerified => verificationStatus == 'verified';
  String? get logoUrl => ApiClient.fileUrl(logo);

  factory CompanyModel.fromJson(Map<String, dynamic> j) => CompanyModel(
        id: '${j['_id']}',
        name: '${j['name'] ?? ''}',
        logo: j['logo'] as String?,
        sector: j['sector'] as String?,
        description: j['description'] as String?,
        wilaya: j['wilaya'] as String?,
        verificationStatus: '${j['verificationStatus'] ?? 'unverified'}',
        website: j['website'] as String?,
        employeesRange: j['employeesRange'] as String?,
        activeOffers: _asInt(j['activeOffers']) ?? 0,
      );
}

class JobOffer {
  final String id;
  final String title;
  final String profession;
  final String sector;
  final String wilaya;
  final String contractType;
  final int? salaryMin;
  final int? salaryMax;
  final String description;
  final List<String> skills;
  final String? educationLevel;
  final String? experienceLevel;
  final String status;
  final bool featured;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final int viewsCount;
  final int applicationsCount;
  final CompanyModel? company;
  final bool isSaved;
  final String? rejectionReason;

  JobOffer({
    required this.id,
    required this.title,
    required this.profession,
    required this.sector,
    required this.wilaya,
    required this.contractType,
    required this.description,
    this.salaryMin,
    this.salaryMax,
    this.skills = const [],
    this.educationLevel,
    this.experienceLevel,
    this.status = 'approved',
    this.featured = false,
    this.publishedAt,
    this.expiresAt,
    this.viewsCount = 0,
    this.applicationsCount = 0,
    this.company,
    this.isSaved = false,
    this.rejectionReason,
  });

  factory JobOffer.fromJson(Map<String, dynamic> j) {
    final rawCompany = j['company'];
    return JobOffer(
      id: '${j['_id']}',
      title: '${j['title'] ?? ''}',
      profession: '${j['profession'] ?? ''}',
      sector: '${j['sector'] ?? ''}',
      wilaya: '${j['wilaya'] ?? ''}',
      contractType: '${j['contractType'] ?? ''}',
      salaryMin: _asInt(j['salaryMin']),
      salaryMax: _asInt(j['salaryMax']),
      description: '${j['description'] ?? ''}',
      skills: _asStrings(j['skills']),
      educationLevel: j['educationLevel'] as String?,
      experienceLevel: j['experienceLevel'] as String?,
      status: '${j['status'] ?? 'approved'}',
      featured: j['featured'] == true,
      publishedAt: _asDate(j['publishedAt']),
      expiresAt: _asDate(j['expiresAt']),
      viewsCount: _asInt(j['viewsCount']) ?? 0,
      applicationsCount: _asInt(j['applicationsCount']) ?? 0,
      // قد تصل المؤسسة ككائن كامل أو كمعرّف فقط
      company: rawCompany is Map<String, dynamic>
          ? CompanyModel.fromJson(rawCompany)
          : null,
      isSaved: j['isSaved'] == true,
      rejectionReason: j['rejectionReason'] as String?,
    );
  }

  /// نص الراتب كما يظهر في البطاقة: «50,000 - 80,000 دج»
  String get salaryLabel {
    String fmt(int v) => v.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

    if (salaryMin != null && salaryMax != null) {
      return '${fmt(salaryMin!)} - ${fmt(salaryMax!)} دج';
    }
    if (salaryMin != null) return 'ابتداءً من ${fmt(salaryMin!)} دج';
    if (salaryMax != null) return 'حتى ${fmt(salaryMax!)} دج';
    return 'الراتب غير محدّد';
  }
}

class ApplicationModel {
  final String id;
  final String status;
  final String? coverLetter;
  final String? statusNote;
  final DateTime? createdAt;
  final JobOffer? offer;
  final UserModel? applicant;
  final Map<String, dynamic>? cvSnapshot;
  final bool viewedByCompany;

  ApplicationModel({
    required this.id,
    required this.status,
    this.coverLetter,
    this.statusNote,
    this.createdAt,
    this.offer,
    this.applicant,
    this.cvSnapshot,
    this.viewedByCompany = false,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> j) {
    final rawOffer = j['offer'];
    final rawApplicant = j['applicant'];
    return ApplicationModel(
      id: '${j['_id']}',
      status: '${j['status'] ?? 'pending'}',
      coverLetter: j['coverLetter'] as String?,
      statusNote: j['statusNote'] as String?,
      createdAt: _asDate(j['createdAt']),
      offer: rawOffer is Map<String, dynamic> ? JobOffer.fromJson(rawOffer) : null,
      applicant:
          rawApplicant is Map<String, dynamic> ? UserModel.fromJson(rawApplicant) : null,
      cvSnapshot: j['cvSnapshot'] as Map<String, dynamic>?,
      viewedByCompany: j['viewedByCompany'] == true,
    );
  }
}

class ProfileModel {
  final String id;
  final String? headline;
  final String? bio;
  final String? sector;
  final String? profession;
  final String? educationLevel;
  final int yearsOfExperience;
  final List<String> skills;
  final List<dynamic> experiences;
  final List<dynamic> educations;
  final List<dynamic> languages;
  final String? cvFile;
  final String? cvFileName;
  final int completion;

  ProfileModel({
    required this.id,
    this.headline,
    this.bio,
    this.sector,
    this.profession,
    this.educationLevel,
    this.yearsOfExperience = 0,
    this.skills = const [],
    this.experiences = const [],
    this.educations = const [],
    this.languages = const [],
    this.cvFile,
    this.cvFileName,
    this.completion = 0,
  });

  String? get cvUrl => ApiClient.fileUrl(cvFile);

  factory ProfileModel.fromJson(Map<String, dynamic> j) => ProfileModel(
        id: '${j['_id']}',
        headline: j['headline'] as String?,
        bio: j['bio'] as String?,
        sector: j['sector'] as String?,
        profession: j['profession'] as String?,
        educationLevel: j['educationLevel'] as String?,
        yearsOfExperience: _asInt(j['yearsOfExperience']) ?? 0,
        skills: _asStrings(j['skills']),
        experiences: (j['experiences'] as List?) ?? const [],
        educations: (j['educations'] as List?) ?? const [],
        languages: (j['languages'] as List?) ?? const [],
        cvFile: j['cvFile'] as String?,
        cvFileName: j['cvFileName'] as String?,
        completion: _asInt(j['completion']) ?? 0,
      );
}

class ConversationModel {
  final String id;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final UserModel? otherParty;
  final String? offerTitle;

  ConversationModel({
    required this.id,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.otherParty,
    this.offerTitle,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> j) {
    final other = j['otherParty'];
    final offer = j['offer'];
    return ConversationModel(
      id: '${j['_id']}',
      lastMessage: j['lastMessage'] as String?,
      lastMessageAt: _asDate(j['lastMessageAt']),
      unreadCount: _asInt(j['unreadCount']) ?? 0,
      otherParty: other is Map<String, dynamic> ? UserModel.fromJson(other) : null,
      offerTitle: offer is Map<String, dynamic> ? offer['title'] as String? : null,
    );
  }
}

class MessageModel {
  final String id;
  final String senderId;
  final String body;
  final DateTime? createdAt;
  final DateTime? readAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.body,
    this.createdAt,
    this.readAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> j) {
    final sender = j['sender'];
    return MessageModel(
      id: '${j['_id']}',
      senderId: sender is Map ? '${sender['_id']}' : '$sender',
      body: '${j['body'] ?? ''}',
      createdAt: _asDate(j['createdAt']),
      readAt: _asDate(j['readAt']),
    );
  }
}

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String? body;
  final Map<String, dynamic>? data;
  final DateTime? createdAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.data,
    this.createdAt,
    this.readAt,
  });

  bool get isRead => readAt != null;

  factory NotificationModel.fromJson(Map<String, dynamic> j) => NotificationModel(
        id: '${j['_id']}',
        type: '${j['type'] ?? ''}',
        title: '${j['title'] ?? ''}',
        body: j['body'] as String?,
        data: j['data'] as Map<String, dynamic>?,
        createdAt: _asDate(j['createdAt']),
        readAt: _asDate(j['readAt']),
      );
}

class BannerModel {
  final String id;
  final String title;
  final String? subtitle;
  final String? ctaLabel;
  final String? image;

  BannerModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.image,
  });

  String? get imageUrl => ApiClient.fileUrl(image);

  factory BannerModel.fromJson(Map<String, dynamic> j) => BannerModel(
        id: '${j['_id']}',
        title: '${j['title'] ?? ''}',
        subtitle: j['subtitle'] as String?,
        ctaLabel: j['ctaLabel'] as String?,
        image: j['image'] as String?,
      );
}

/// عنصر مرجعي (ولاية، قطاع، نوع عقد…) بمفتاح وتسمية عربية
class RefItem {
  final String key;
  final String label;

  const RefItem(this.key, this.label);

  factory RefItem.fromJson(Map<String, dynamic> j) =>
      RefItem('${j['key'] ?? j['ar']}', '${j['ar']}');
}
