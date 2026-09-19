import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/labels.dart';
import '../models/models.dart';

/// شعار التطبيق: عدسة بحث + حقيبة، «بحث عن» أبيض و«عمل» ذهبي
class AppLogo extends StatelessWidget {
  final double size;
  final bool light;

  const AppLogo({super.key, this.size = 64, this.light = true});

  @override
  Widget build(BuildContext context) {
    final fg = light ? Colors.white : AppColors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: light ? Colors.white.withValues(alpha: 0.12) : AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold, width: size * 0.045),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.person_search_rounded, size: size * 0.5, color: fg),
              Positioned(
                bottom: size * 0.14,
                left: size * 0.14,
                child: Icon(Icons.work_rounded, size: size * 0.26, color: AppColors.gold),
              ),
            ],
          ),
        ),
        SizedBox(height: size * 0.18),
        RichText(
          text: TextSpan(
            style: TextStyle(fontSize: size * 0.34, fontWeight: FontWeight.w800, height: 1.2),
            children: [
              TextSpan(text: 'بحث عن ', style: TextStyle(color: fg)),
              const TextSpan(text: 'عمل', style: TextStyle(color: AppColors.gold)),
            ],
          ),
        ),
        Text(
          'DZ',
          style: TextStyle(
            fontSize: size * 0.26,
            fontWeight: FontWeight.w800,
            color: AppColors.gold,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

/// خطّ أفق المدينة الجزائرية أسفل الشاشات الزرقاء (كما في التصميم)
class SkylinePainter extends CustomPainter {
  final Color color;

  SkylinePainter({this.color = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.18);
    // أعمدة بارتفاعات متفاوتة توحي بأفق مدينة
    const heights = [0.45, 0.72, 0.35, 0.88, 0.52, 0.66, 0.40, 0.78, 0.30, 0.60, 0.48, 0.82];
    final barWidth = size.width / (heights.length * 1.6);

    for (var i = 0; i < heights.length; i++) {
      final x = i * barWidth * 1.6 + barWidth * 0.3;
      final h = size.height * heights[i];
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, size.height - h, barWidth, h),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SkylinePainter old) => old.color != color;
}

/// شارة «مؤسسة موثّقة» (3.8)
class VerifiedBadge extends StatelessWidget {
  final double size;
  const VerifiedBadge({super.key, this.size = 16});

  @override
  Widget build(BuildContext context) => Icon(
        Icons.verified_rounded,
        size: size,
        color: AppColors.info,
        semanticLabel: 'مؤسسة موثّقة',
      );
}

/// شارة نوع العقد الملوّنة
class ContractChip extends StatelessWidget {
  final String contractType;
  const ContractChip({super.key, required this.contractType});

  static const _colors = {
    'full_time': AppColors.success,
    'part_time': AppColors.warning,
    'cdd': AppColors.info,
    'internship': AppColors.tilePurple,
    'seasonal': AppColors.tileOrange,
    'remote': AppColors.tileTeal,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[contractType] ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        Labels.contract(contractType),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

/// شعار المؤسسة أو أيقونة القطاع البديلة
class CompanyAvatar extends StatelessWidget {
  final CompanyModel? company;
  final String? sector;
  final double size;

  const CompanyAvatar({super.key, this.company, this.sector, this.size = 48});

  static const _sectorIcons = {
    'construction': Icons.engineering_rounded,
    'transport': Icons.local_shipping_rounded,
    'hospitality': Icons.restaurant_rounded,
    'industry': Icons.factory_rounded,
    'commerce': Icons.storefront_rounded,
    'it': Icons.computer_rounded,
    'health': Icons.local_hospital_rounded,
    'education': Icons.school_rounded,
    'agriculture': Icons.agriculture_rounded,
    'services': Icons.support_agent_rounded,
    'crafts': Icons.handyman_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final url = company?.logoUrl;
    final key = company?.sector ?? sector;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _fallback(key, size),
              placeholder: (_, __) => _fallback(key, size),
            )
          : _fallback(key, size),
    );
  }

  static Widget _fallback(String? sector, double size) => Icon(
        _sectorIcons[sector] ?? Icons.business_rounded,
        size: size * 0.5,
        color: AppColors.primary,
      );
}

/// بطاقة عرض العمل — التصميم المستعمل في كل القوائم
class JobCard extends StatelessWidget {
  final JobOffer offer;
  final VoidCallback? onTap;
  final VoidCallback? onSaveToggle;
  final bool showSaveButton;

  const JobCard({
    super.key,
    required this.offer,
    this.onTap,
    this.onSaveToggle,
    this.showSaveButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CompanyAvatar(company: offer.company, sector: offer.sector),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            offer.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (offer.featured)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'مميّز',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF8A6200),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            offer.company?.name ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (offer.company?.isVerified ?? false) ...[
                          const SizedBox(width: 4),
                          const VerifiedBadge(size: 13),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 13, color: AppColors.tileGreen),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            offer.wilaya,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ContractChip(contractType: offer.contractType),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (showSaveButton)
                    InkWell(
                      onTap: onSaveToggle,
                      borderRadius: BorderRadius.circular(22),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          offer.isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          size: 20,
                          color: offer.isSaved
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                    )
                  else
                    const Icon(Icons.chevron_left_rounded,
                        color: AppColors.textMuted, size: 22),
                  const SizedBox(height: 6),
                  Text(
                    timeAgo(offer.publishedAt),
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// حالة فارغة برسالة عربية وأيقونة
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 44, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
              if (action != null) ...[const SizedBox(height: 20), action!],
            ],
          ),
        ),
      );
}

/// رسالة خطأ مع زر إعادة المحاولة
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'تعذّر تحميل البيانات',
        subtitle: message,
        action: onRetry == null
            ? null
            : SizedBox(
                width: 180,
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة'),
                ),
              ),
      );
}

/// هيكل تحميل متحرّك بدل دوّارة فارغة
class JobCardSkeleton extends StatelessWidget {
  const JobCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: const Color(0xFFE8EDF3),
        highlightColor: const Color(0xFFF7F9FC),
        child: Container(
          height: 92,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
}

/// عرض رسالة قصيرة أسفل الشاشة
void showSnack(BuildContext context, String message, {bool error = false}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.danger : AppColors.success,
      duration: const Duration(seconds: 3),
    ));
}
