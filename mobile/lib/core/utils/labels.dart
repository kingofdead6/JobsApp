/// التسميات العربية للمفاتيح التقنية القادمة من الـ API.
/// مضمّنة محليًا حتى تعمل الواجهة دون انتظار نداء المراجع.
class Labels {
  Labels._();

  static const Map<String, String> contractTypes = {
    'full_time': 'دوام كامل',
    'part_time': 'دوام جزئي',
    'cdd': 'مؤقت',
    'internship': 'تربّص',
    'seasonal': 'عمل موسمي',
    'remote': 'عن بُعد',
  };

  static const Map<String, String> sectors = {
    'construction': 'البناء والأشغال العمومية',
    'transport': 'النقل واللوجستيك',
    'hospitality': 'المطاعم والفندقة',
    'industry': 'الصناعة',
    'commerce': 'التجارة',
    'it': 'الإعلام الآلي',
    'health': 'الصحة',
    'education': 'التعليم',
    'agriculture': 'الفلاحة',
    'services': 'الخدمات',
    'crafts': 'الحرف',
  };

  static const Map<String, String> educationLevels = {
    'none': 'دون مستوى',
    'primary': 'ابتدائي',
    'middle': 'متوسط',
    'secondary': 'ثانوي',
    'vocational': 'تكوين مهني',
    'bac': 'بكالوريا',
    'licence': 'ليسانس',
    'master': 'ماستر',
    'doctorate': 'دكتوراه',
  };

  static const Map<String, String> experienceLevels = {
    'none': 'بدون خبرة',
    'junior': 'أقل من سنتين',
    'mid': 'من 2 إلى 5 سنوات',
    'senior': 'أكثر من 5 سنوات',
  };

  static const Map<String, String> applicationStatus = {
    'pending': 'قيد الدراسة',
    'accepted': 'مقبول',
    'rejected': 'مرفوض',
  };

  static const Map<String, String> offerStatus = {
    'pending': 'قيد المراجعة',
    'approved': 'منشور',
    'rejected': 'مرفوض',
    'paused': 'موقوف',
    'expired': 'منتهٍ',
  };

  static const Map<String, String> reportReasons = {
    'fake': 'عرض وهمي',
    'scam': 'محاولة احتيال',
    'money_request': 'طلب مال',
    'offensive': 'محتوى مسيء',
    'duplicate': 'عرض مكرر',
    'other': 'سبب آخر',
  };

  static const Map<String, String> languageLevels = {
    'basic': 'مبتدئ',
    'good': 'جيّد',
    'fluent': 'طليق',
    'native': 'لغة أم',
  };

  static String contract(String? k) => contractTypes[k] ?? k ?? '';
  static String sector(String? k) => sectors[k] ?? k ?? '';
  static String education(String? k) => educationLevels[k] ?? k ?? '';
  static String experience(String? k) => experienceLevels[k] ?? k ?? '';
  static String appStatus(String? k) => applicationStatus[k] ?? k ?? '';
  static String offer(String? k) => offerStatus[k] ?? k ?? '';

  /// الولايات الـ58 مرتّبة حسب الترقيم الرسمي
  static const List<String> wilayas = [
    'أدرار',
    'الشلف',
    'الأغواط',
    'أم البواقي',
    'باتنة',
    'بجاية',
    'بسكرة',
    'بشار',
    'البليدة',
    'البويرة',
    'تمنراست',
    'تبسة',
    'تلمسان',
    'تيارت',
    'تيزي وزو',
    'الجزائر العاصمة',
    'الجلفة',
    'جيجل',
    'سطيف',
    'سعيدة',
    'سكيكدة',
    'سيدي بلعباس',
    'عنابة',
    'قالمة',
    'قسنطينة',
    'المدية',
    'مستغانم',
    'المسيلة',
    'معسكر',
    'ورقلة',
    'وهران',
    'البيض',
    'إليزي',
    'برج بوعريريج',
    'بومرداس',
    'الطارف',
    'تندوف',
    'تيسمسيلت',
    'الوادي',
    'خنشلة',
    'سوق أهراس',
    'تيبازة',
    'ميلة',
    'عين الدفلى',
    'النعامة',
    'عين تموشنت',
    'غرداية',
    'غليزان',
    'تيميمون',
    'برج باجي مختار',
    'أولاد جلال',
    'بني عباس',
    'عين صالح',
    'عين قزام',
    'تقرت',
    'جانت',
    'المغير',
    'المنيعة',
  ];
}

/// صياغة الوقت النسبي بالعربية: «منذ 3 ساعات»
String timeAgo(DateTime? date) {
  if (date == null) return '';
  final diff = DateTime.now().difference(date);

  if (diff.inSeconds < 60) return 'الآن';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    if (m == 1) return 'منذ دقيقة';
    if (m == 2) return 'منذ دقيقتين';
    return m <= 10 ? 'منذ $m دقائق' : 'منذ $m دقيقة';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    if (h == 1) return 'منذ ساعة';
    if (h == 2) return 'منذ ساعتين';
    return h <= 10 ? 'منذ $h ساعات' : 'منذ $h ساعة';
  }
  if (diff.inDays < 30) {
    final d = diff.inDays;
    if (d == 1) return 'أمس';
    if (d == 2) return 'منذ يومين';
    return d <= 10 ? 'منذ $d أيام' : 'منذ $d يومًا';
  }
  final months = (diff.inDays / 30).floor();
  if (months == 1) return 'منذ شهر';
  if (months == 2) return 'منذ شهرين';
  if (months < 12) return 'منذ $months أشهر';

  final years = (diff.inDays / 365).floor();
  return years == 1 ? 'منذ سنة' : 'منذ $years سنوات';
}
