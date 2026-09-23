import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';
import '../../models/models.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';
import '../jobs/job_detail_screen.dart';

/// صفحة تعريف المؤسسة وعروضها النشطة (3.8)
class CompanyDetailScreen extends StatefulWidget {
  final String companyId;
  const CompanyDetailScreen({super.key, required this.companyId});

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {
  CompanyModel? _company;
  List<JobOffer> _offers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final (company, offers) = await CompanyService.detail(widget.companyId);
      if (!mounted) return;
      setState(() {
        _company = company;
        _offers = offers;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),title: const Text('المؤسسة')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _company == null) {
      return Scaffold(
        appBar: AppBar(
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),title: const Text('المؤسسة')),
        body: ErrorState(message: _error ?? 'غير موجودة', onRetry: _load),
      );
    }

    final c = _company!;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ترويسة
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CompanyAvatar(company: c, size: 72),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          c.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (c.isVerified) ...[
                        const SizedBox(width: 6),
                        Icon(PhosphorIcons.sealCheck(PhosphorIconsStyle.fill),
                            color: Colors.white, size: 19),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    Labels.sector(c.sector),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  if (c.isVerified) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIcons.sealCheck(PhosphorIconsStyle.fill),
                              size: 14, color: Colors.white),
                          const SizedBox(width: 5),
                          const Text(
                            'مؤسسة موثّقة',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _row(PhosphorIcons.mapPin(PhosphorIconsStyle.fill), 'الولاية',
                              c.wilaya ?? '-'),
                          if (c.employeesRange != null)
                            _row(PhosphorIcons.usersThree(PhosphorIconsStyle.fill), 'عدد العمال',
                                c.employeesRange!),
                          if (c.website != null && c.website!.isNotEmpty)
                            InkWell(
                              onTap: () async {
                                var url = c.website!;
                                if (!url.startsWith('http')) {
                                  url = 'https://$url';
                                }
                                await launchUrl(Uri.parse(url),
                                    mode: LaunchMode.externalApplication);
                              },
                              child: _row(PhosphorIcons.globe(PhosphorIconsStyle.bold), 'الموقع',
                                  c.website!,
                                  link: true),
                            ),
                        ],
                      ),
                    ),
                  ),

                  if (c.description != null && c.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('عن المؤسسة',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                      c.description!,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],

                  const SizedBox(height: 22),
                  Text(
                    'العروض النشطة (${_offers.length})',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),

                  if (_offers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'لا توجد عروض نشطة حاليًا',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textMuted),
                      ),
                    )
                  else
                    ..._offers.map((o) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: JobCard(
                            offer: o,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      JobDetailScreen(offerId: o.id)),
                            ),
                          ),
                        )),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, {bool link = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 17, color: AppColors.primary),
            const SizedBox(width: 10),
            Text('$label: ',
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary)),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: link ? AppColors.info : AppColors.textPrimary,
                  decoration: link ? TextDecoration.underline : null,
                ),
              ),
            ),
          ],
        ),
      );
}
