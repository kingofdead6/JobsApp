import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';
import 'edit_profile_screen.dart';

/// السيرة الذاتية الرقمية (3.5)
class CvScreen extends StatefulWidget {
  const CvScreen({super.key});

  @override
  State<CvScreen> createState() => _CvScreenState();
}

class _CvScreenState extends State<CvScreen> {
  ProfileModel? _profile;
  UserModel? _user;
  bool _loading = true;
  String? _error;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final (profile, user) = await ProfileService.me();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _user = user;
        _loading = false;
      });
      context.read<AuthProvider>().setProfile(profile);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _pickCv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    final path = result?.files.single.path;
    if (path == null) return;

    setState(() => _uploading = true);
    try {
      final profile = await ProfileService.uploadCv(path);
      if (!mounted) return;
      setState(() => _profile = profile);
      showSnack(context, 'تم رفع السيرة الذاتية');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final user = await ProfileService.uploadAvatar(picked.path);
      if (!mounted) return;
      setState(() => _user = user);
      context.read<AuthProvider>().setUser(user);
      showSnack(context, 'تم تحديث الصورة');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removeExperience(String id) async {
    try {
      final profile = await ProfileService.removeExperience(id);
      if (!mounted) return;
      setState(() => _profile = profile);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _removeEducation(String id) async {
    try {
      final profile = await ProfileService.removeEducation(id);
      if (!mounted) return;
      setState(() => _profile = profile);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),        title: const Text('سيرتي الذاتية'),
        actions: [
          if (!_loading && _profile != null)
            IconButton(
              tooltip: 'تعديل',
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(
                    profile: _profile!,
                    user: _user!,
                  ),
                ),
              ).then((_) => _load()),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _headerCard(),
                      const SizedBox(height: 16),
                      _completionCard(),
                      const SizedBox(height: 16),
                      _cvFileCard(),
                      const SizedBox(height: 16),
                      _personalInfo(),
                      const SizedBox(height: 16),
                      _experiencesSection(),
                      const SizedBox(height: 16),
                      _educationsSection(),
                      const SizedBox(height: 16),
                      _skillsSection(),
                      const SizedBox(height: 16),
                      _languagesSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _headerCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: _user?.avatarUrl != null
                        ? NetworkImage(_user!.avatarUrl!)
                        : null,
                    child: _user?.avatarUrl == null
                        ? const Icon(Icons.person_rounded,
                            size: 34, color: AppColors.primary)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: GestureDetector(
                      onTap: _uploading ? null : _pickAvatar,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            size: 13, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _user?.fullName ?? '',
                      style: const TextStyle(
                          fontSize: 16.5, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _profile?.headline ?? 'أضف مسمّاك المهني',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                    if (_user?.wilaya != null) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 13, color: AppColors.tileGreen),
                          const SizedBox(width: 3),
                          Text(
                            _user!.wilaya!,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  /// مؤشّر اكتمال الملف (%) — يحفّز المستخدم على إتمامه
  Widget _completionCard() {
    final pct = _profile?.completion ?? 0;
    final color = pct >= 80
        ? AppColors.success
        : pct >= 50
            ? AppColors.warning
            : AppColors.danger;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('اكتمال الملف',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                Text(
                  '$pct%',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800, color: color),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            if (pct < 100) ...[
              const SizedBox(height: 8),
              const Text(
                'أكمل ملفك لترفع فرص قبول ترشّحك',
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cvFileCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded,
                    color: AppColors.danger, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ملف السيرة الذاتية (PDF)',
                        style: TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(
                      _profile?.cvFileName ?? 'لم تُرفع أي نسخة بعد',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              _uploading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : TextButton(
                      onPressed: _pickCv,
                      child: Text(_profile?.cvFile == null ? 'رفع' : 'تغيير'),
                    ),
            ],
          ),
        ),
      );

  Widget _personalInfo() => _section(
        title: 'معلومات شخصية',
        child: Column(
          children: [
            _infoRow('الاسم الكامل', _user?.fullName ?? '-'),
            _infoRow('رقم الهاتف', _user?.phone ?? '-'),
            _infoRow('البريد الإلكتروني', _user?.email ?? '-'),
            _infoRow('الولاية', _user?.wilaya ?? '-'),
            _infoRow('المهنة', _profile?.profession ?? '-'),
            _infoRow('المستوى الدراسي',
                Labels.education(_profile?.educationLevel).isEmpty
                    ? '-'
                    : Labels.education(_profile?.educationLevel)),
            _infoRow('سنوات الخبرة', '${_profile?.yearsOfExperience ?? 0}'),
          ],
        ),
      );

  Widget _experiencesSection() => _section(
        title: 'الخبرات المهنية',
        child: (_profile?.experiences.isEmpty ?? true)
            ? _emptyHint('لم تُضف أي خبرة مهنية بعد')
            : Column(
                children: _profile!.experiences.map((e) {
                  final map = e as Map<String, dynamic>;
                  final start = DateTime.tryParse('${map['startDate']}');
                  final end = DateTime.tryParse('${map['endDate']}');
                  final period = '${start?.year ?? ''} - '
                      '${map['current'] == true ? 'الآن' : (end?.year ?? '')}';

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.work_rounded,
                          size: 18, color: AppColors.primary),
                    ),
                    title: Text('${map['title'] ?? ''}',
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      '${map['company'] ?? ''} · $period',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 19, color: AppColors.danger),
                      onPressed: () => _removeExperience('${map['_id']}'),
                    ),
                  );
                }).toList(),
              ),
      );

  Widget _educationsSection() => _section(
        title: 'الشهادات',
        child: (_profile?.educations.isEmpty ?? true)
            ? _emptyHint('لم تُضف أي شهادة بعد')
            : Column(
                children: _profile!.educations.map((e) {
                  final map = e as Map<String, dynamic>;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.tilePurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.school_rounded,
                          size: 18, color: AppColors.tilePurple),
                    ),
                    title: Text('${map['degree'] ?? ''}',
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      '${map['institution'] ?? ''} ${map['year'] != null ? '· ${map['year']}' : ''}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 19, color: AppColors.danger),
                      onPressed: () => _removeEducation('${map['_id']}'),
                    ),
                  );
                }).toList(),
              ),
      );

  Widget _skillsSection() => _section(
        title: 'المهارات',
        child: (_profile?.skills.isEmpty ?? true)
            ? _emptyHint('لم تُضف أي مهارة بعد')
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _profile!.skills
                    .map((s) => Chip(
                          label: Text(s, style: const TextStyle(fontSize: 12)),
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.07),
                          side: BorderSide.none,
                        ))
                    .toList(),
              ),
      );

  Widget _languagesSection() => _section(
        title: 'اللغات',
        child: (_profile?.languages.isEmpty ?? true)
            ? _emptyHint('لم تُضف أي لغة بعد')
            : Column(
                children: _profile!.languages.map((l) {
                  final map = l as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${map['name'] ?? ''}',
                            style: const TextStyle(fontSize: 13.5)),
                        Text(
                          Labels.languageLevels['${map['level']}'] ?? '',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
      );

  Widget _section({required String title, required Widget child}) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      );

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

  Widget _emptyHint(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
        ),
      );
}
