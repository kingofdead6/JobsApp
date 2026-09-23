import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/labels.dart';
import '../models/models.dart';

/// ─────────────────────────────────────────────────────────────
/// الحركة: عناصر تدخل بتدرّج لطيف بدل الظهور المفاجئ
/// ─────────────────────────────────────────────────────────────

/// يُظهر العنصر بتلاشٍ وانزلاق لأعلى، مع تأخير حسب ترتيبه في القائمة.
class FadeInUp extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration duration;
  final double offset;

  const FadeInUp({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = AppMotion.slow,
    this.offset = 18,
  });

  @override
  State<FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<FadeInUp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    // تأخير تدريجي محدود حتى لا تتأخّر العناصر البعيدة كثيرًا
    final delay = Duration(milliseconds: (widget.index.clamp(0, 8)) * 55);
    Future.delayed(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: AppMotion.curve);
    return FadeTransition(
      opacity: curved,
      child: AnimatedBuilder(
        animation: curved,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, widget.offset * (1 - curved.value)),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// يصغر العنصر قليلًا عند الضغط — استجابة لمسية محسوسة
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final BorderRadius? borderRadius;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.borderRadius,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:
          widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapUp:
          widget.onTap == null ? null : (_) => setState(() => _down = false),
      onTapCancel:
          widget.onTap == null ? null : () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        child: widget.child,
      ),
    );
  }
}

/// عدّاد رقمي يتحرّك من 0 إلى القيمة — يُستعمل في الإحصائيات
class AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final String suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<int>(
        tween: IntTween(begin: 0, end: value),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => Text('$v$suffix', style: style),
      );
}

/// ─────────────────────────────────────────────────────────────
/// الهوية البصرية
/// ─────────────────────────────────────────────────────────────

/// شعار التطبيق: عدسة بحث + حقيبة، «بحث عن» ثمّ «عمل» ذهبي
class AppLogo extends StatelessWidget {
  final double size;
  final bool light;
  final bool showTagline;

  const AppLogo({
    super.key,
    this.size = 64,
    this.light = true,
    this.showTagline = false,
  });

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
            gradient: light
                ? LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Colors.white.withValues(alpha: 0.22),
                      Colors.white.withValues(alpha: 0.08),
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [AppColors.primarySoft, Color(0xFFDDE8FA)],
                  ),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold, width: size * 0.048),
            boxShadow: AppShadows.colored(AppColors.gold, opacity: 0.22),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.search_rounded, size: size * 0.44, color: fg),
              Positioned(
                bottom: size * 0.15,
                left: size * 0.15,
                child: Container(
                  padding: EdgeInsets.all(size * 0.045),
                  decoration: const BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.work_rounded,
                    size: size * 0.2,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: size * 0.2),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: size * 0.33,
              fontWeight: FontWeight.w900,
              height: 1.2,
              letterSpacing: -0.5,
            ),
            children: [
              TextSpan(text: 'بحث عن ', style: TextStyle(color: fg)),
              const TextSpan(
                  text: 'عمل', style: TextStyle(color: AppColors.gold)),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: size * 0.04),
          padding: EdgeInsets.symmetric(
              horizontal: size * 0.14, vertical: size * 0.03),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: light ? 0.18 : 0.14),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            'DZ',
            style: TextStyle(
              fontSize: size * 0.17,
              fontWeight: FontWeight.w900,
              color: light ? AppColors.goldLight : AppColors.goldDark,
              letterSpacing: 3,
            ),
          ),
        ),
        if (showTagline) ...[
          SizedBox(height: size * 0.16),
          Text(
            'فرصتك للعمل تبدأ من هنا',
            style: TextStyle(
              fontSize: size * 0.145,
              color: light ? Colors.white70 : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// خطّ أفق المدينة الجزائرية أسفل الشاشات الزرقاء
class SkylinePainter extends CustomPainter {
  final Color color;
  final double opacity;

  SkylinePainter({this.color = Colors.white, this.opacity = 0.16});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: opacity);
    const heights = [
      0.42,
      0.70,
      0.33,
      0.86,
      0.50,
      0.64,
      0.38,
      0.76,
      0.28,
      0.58,
      0.46,
      0.80,
      0.35,
      0.68,
    ];
    final barWidth = size.width / (heights.length * 1.55);

    for (var i = 0; i < heights.length; i++) {
      final x = i * barWidth * 1.55 + barWidth * 0.28;
      final h = size.height * heights[i];
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, size.height - h, barWidth, h),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        ),
        paint,
      );
      // نوافذ صغيرة توحي بالحياة
      if (heights[i] > 0.5) {
        final wp = Paint()..color = color.withValues(alpha: opacity * 0.7);
        for (var r = 0; r < 3; r++) {
          canvas.drawRect(
            Rect.fromLTWH(x + barWidth * 0.28, size.height - h + 10 + r * 14,
                barWidth * 0.42, 5),
            wp,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant SkylinePainter old) =>
      old.color != color || old.opacity != opacity;
}

/// ترويسة متدرّجة بمنحنى سفلي — تُستعمل أعلى الشاشات
class GradientHeader extends StatelessWidget {
  final Widget child;
  final double height;
  final bool showSkyline;
  final EdgeInsets padding;

  const GradientHeader({
    super.key,
    required this.child,
    this.height = 0,
    this.showSkyline = false,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 22),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height > 0 ? height : null,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // دائرة زخرفية شفّافة تكسر السطح المصمت
          Positioned(
            top: -40,
            left: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.08),
              ),
            ),
          ),
          if (showSkyline)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomPaint(
                size: const Size(double.infinity, 56),
                painter: SkylinePainter(opacity: 0.12),
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// عناصر متكرّرة
/// ─────────────────────────────────────────────────────────────

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
  final bool compact;

  const ContractChip({
    super.key,
    required this.contractType,
    this.compact = true,
  });

  static const _colors = {
    'full_time': AppColors.success,
    'part_time': AppColors.warning,
    'cdd': AppColors.info,
    'internship': AppColors.tilePurple,
    'seasonal': AppColors.tileOrange,
    'remote': AppColors.tileTeal,
  };

  static IconData iconFor(String key) => switch (key) {
        'full_time' => Icons.schedule_rounded,
        'part_time' => Icons.timelapse_rounded,
        'cdd' => Icons.calendar_today_rounded,
        'internship' => Icons.school_rounded,
        'seasonal' => Icons.wb_sunny_rounded,
        'remote' => Icons.home_rounded,
        _ => Icons.work_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final color = _colors[contractType] ?? AppColors.textSecondary;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 9 : 12, vertical: compact ? 4 : 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconFor(contractType), size: compact ? 11 : 13, color: color),
          const SizedBox(width: 4),
          Text(
            Labels.contract(contractType),
            style: TextStyle(
              fontSize: compact ? 10.5 : 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// شارة «مميّز» الذهبية
class FeaturedBadge extends StatelessWidget {
  const FeaturedBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: AppShadows.colored(AppColors.gold, opacity: 0.30),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: 10, color: AppColors.primaryDark),
            SizedBox(width: 3),
            Text(
              'مميّز',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      );
}

/// شارة حالة عامة (قيد الدراسة / مقبول / منشور …)
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      );
}

/// شعار المؤسسة أو أيقونة القطاع البديلة
class CompanyAvatar extends StatelessWidget {
  final CompanyModel? company;
  final String? sector;
  final double size;

  const CompanyAvatar({
    super.key,
    this.company,
    this.sector,
    this.size = 48,
  });

  static IconData sectorIcon(String? sector) => switch (sector) {
        'construction' => Icons.handyman_rounded,
        'transport' => Icons.local_shipping_rounded,
        'hospitality' => Icons.restaurant_rounded,
        'industry' => Icons.factory_rounded,
        'commerce' => Icons.storefront_rounded,
        'it' => Icons.computer_rounded,
        'health' => Icons.local_hospital_rounded,
        'education' => Icons.school_rounded,
        'agriculture' => Icons.agriculture_rounded,
        'services' => Icons.support_agent_rounded,
        'crafts' => Icons.build_rounded,
        _ => Icons.business_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final url = company?.logoUrl;
    final key = company?.sector ?? sector;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.primarySoft, Color(0xFFDFE9FA)],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              fadeInDuration: AppMotion.normal,
              errorWidget: (_, __, ___) => _fallback(key, size),
              placeholder: (_, __) => _fallback(key, size),
            )
          : _fallback(key, size),
    );
  }

  static Widget _fallback(String? sector, double size) => Icon(
        sectorIcon(sector),
        size: size * 0.5,
        color: AppColors.primary,
      );
}

/// بطاقة عرض العمل — العنصر الأكثر تكرارًا في التطبيق
class JobCard extends StatelessWidget {
  final JobOffer offer;
  final VoidCallback? onTap;
  final VoidCallback? onSaveToggle;
  final bool showSaveButton;
  final int index;

  const JobCard({
    super.key,
    required this.offer,
    this.onTap,
    this.onSaveToggle,
    this.showSaveButton = false,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      index: index,
      child: PressableScale(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: offer.featured
                  ? AppColors.gold.withValues(alpha: 0.42)
                  : AppColors.border,
              width: offer.featured ? 1.4 : 1,
            ),
            boxShadow: AppShadows.card,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'offer-avatar-${offer.id}',
                      child: CompanyAvatar(
                          company: offer.company, sector: offer.sector),
                    ),
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
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              if (offer.featured) ...[
                                const SizedBox(width: 6),
                                const FeaturedBadge(),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
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
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (offer.company?.isVerified ?? false) ...[
                                const SizedBox(width: 4),
                                const VerifiedBadge(size: 13),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (showSaveButton)
                      _SaveButton(saved: offer.isSaved, onTap: onSaveToggle),
                  ],
                ),
                const SizedBox(height: 12),
                Container(height: 1, color: AppColors.border),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 13, color: AppColors.tileGreen),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        offer.wilaya,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ContractChip(contractType: offer.contractType),
                    const Spacer(),
                    Text(
                      timeAgo(offer.publishedAt),
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
                if (offer.salaryMin != null || offer.salaryMax != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.payments_rounded,
                          size: 13, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        offer.salaryLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool saved;
  final VoidCallback? onTap;

  const _SaveButton({required this.saved, this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: AnimatedSwitcher(
              duration: AppMotion.fast,
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                saved ? Icons.bookmark_rounded : Icons.bookmark_rounded,
                key: ValueKey(saved),
                size: 21,
                color: saved ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ),
        ),
      );
}

/// ─────────────────────────────────────────────────────────────
/// حالات الشاشة
/// ─────────────────────────────────────────────────────────────

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: FadeInUp(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(26),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [AppColors.primarySoft, Color(0xFFEDF3FD)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 46, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
                if (action != null) ...[const SizedBox(height: 22), action!],
              ],
            ),
          ),
        ),
      );
}

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
                width: 190,
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
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
        baseColor: const Color(0xFFE8EDF4),
        highlightColor: const Color(0xFFF7FAFD),
        child: Container(
          height: 132,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      );
}

/// دوّارة التحميل الأساسية
class Loader extends StatelessWidget {
  final double size;
  const Loader({super.key, this.size = 34});

  @override
  Widget build(BuildContext context) => Center(
        child: SizedBox(
          width: size,
          height: size,
          child: const CircularProgressIndicator(strokeWidth: 3),
        ),
      );
}

/// ─────────────────────────────────────────────────────────────
/// أدوات
/// ─────────────────────────────────────────────────────────────

void showSnack(BuildContext context, String message, {bool error = false}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(
            error ? Icons.error_rounded : Icons.check_circle_rounded,
            color: Colors.white,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: error ? AppColors.danger : AppColors.success,
      duration: const Duration(seconds: 3),
    ));
}

/// شريط علوي شفّاف فوق ترويسة متدرّجة
PreferredSizeWidget gradientAppBar(
  String title, {
  List<Widget>? actions,
  Widget? leading,
  bool centerTitle = true,
  PreferredSizeWidget? bottom,
}) =>
    AppBar(
      title: Text(title),
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      bottom: bottom,
      flexibleSpace: const DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.primaryGradient),
      ),
    );
