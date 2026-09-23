import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';
import '../company/companies_screen.dart';
import '../company/my_jobs_screen.dart';
import '../company/post_job_screen.dart';
import '../jobs/job_detail_screen.dart';
import '../jobs/jobs_list_screen.dart';
import '../jobs/wilaya_jobs_screen.dart';
import '../profile/cv_screen.dart';
import '../saved/saved_screen.dart';

/// الواجهة الرئيسية (3.2): بحث سريع، ستة مداخل، أحدث العروض
class HomeScreen extends StatefulWidget {
  final void Function(int)? onNavigateTab;
  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = JobService.home();
  }

  Future<void> _reload() async {
    setState(() => _future = JobService.home());
    await _future;
  }

  void _openSearch({String? query}) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => JobsListScreen(initialQuery: query)),
      );

  void _openOffer(JobOffer offer) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => JobDetailScreen(offerId: offer.id)),
      ).then((_) => _reload());

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _reload,
        color: AppColors.primary,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return _loadingView();
            }
            if (snap.hasError) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  ErrorState(
                    message: snap.error is ApiException
                        ? (snap.error as ApiException).message
                        : 'تعذّر الاتصال بالخادم',
                    onRetry: _reload,
                  ),
                ],
              );
            }

            final data = snap.data!;
            final banners = data['banners'] as List<BannerModel>;
            final latest = data['latestOffers'] as List<JobOffer>;
            final featured = data['featuredOffers'] as List<JobOffer>;
            final total = data['totalOffers'] as int;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _header(auth, total)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (banners.isNotEmpty) ...[
                          FadeInUp(child: _banner(banners.first, total)),
                          const SizedBox(height: 20),
                        ],
                        FadeInUp(index: 1, child: _tiles(auth.isCompany)),
                        const SizedBox(height: 24),
                        if (featured.isNotEmpty) ...[
                          FadeInUp(
                            index: 2,
                            child: _sectionHeader(
                              'العروض المميّزة',
                              PhosphorIcons.star(PhosphorIconsStyle.fill),
                              AppColors.gold,
                              onSeeAll: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const JobsListScreen(
                                      featuredOnly: true),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FadeInUp(index: 3, child: _featuredRow(featured)),
                          const SizedBox(height: 24),
                        ],
                        FadeInUp(
                          index: 4,
                          child: _sectionHeader(
                            'أحدث عروض العمل',
                            PhosphorIcons.lightning(PhosphorIconsStyle.fill),
                            AppColors.tileOrange,
                            onSeeAll: _openSearch,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                if (latest.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: EmptyState(
                        icon: PhosphorIcons.briefcase(
                            PhosphorIconsStyle.duotone),
                        title: 'لا توجد عروض منشورة بعد',
                        subtitle: 'عُد لاحقًا، تُضاف عروض جديدة يوميًا',
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    sliver: SliverList.separated(
                      itemCount: latest.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => JobCard(
                        offer: latest[i],
                        index: i,
                        onTap: () => _openOffer(latest[i]),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// ترويسة متدرّجة تحمل الشعار وشريط البحث
  Widget _header(AuthProvider auth, int total) => GradientHeader(
        padding: EdgeInsets.fromLTRB(
            16, MediaQuery.of(context).padding.top + 12, 16, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold),
                    color: Colors.white,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 9),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                        fontSize: 17.5, fontWeight: FontWeight.w900),
                    children: [
                      TextSpan(
                          text: 'بحث عن ',
                          style: TextStyle(color: Colors.white)),
                      TextSpan(
                          text: 'عمل',
                          style: TextStyle(color: AppColors.goldLight)),
                    ],
                  ),
                ),
                const Spacer(),
                _iconButton(
                  PhosphorIcons.bell(PhosphorIconsStyle.regular),
                  () => widget.onNavigateTab?.call(3),
                  tooltip: 'الإشعارات',
                ),
              ],
            ),
            const SizedBox(height: 18),

            // تحية باسم المستخدم
            Text(
              auth.user != null
                  ? 'مرحبًا، ${auth.user!.fullName.split(' ').first} 👋'
                  : 'مرحبًا بك 👋',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                AnimatedCounter(
                  value: total,
                  style: const TextStyle(
                    color: AppColors.goldLight,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  ' عرض عمل في انتظارك',
                  style: TextStyle(color: Colors.white70, fontSize: 13.5),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _searchBar(),
          ],
        ),
      );

  Widget _iconButton(IconData icon, VoidCallback onTap, {String? tooltip}) =>
      Tooltip(
        message: tooltip ?? '',
        child: Material(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      );

  Widget _searchBar() => PressableScale(
        onTap: _openSearch,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: AppShadows.lifted,
          ),
          child: Row(
            children: [
              Icon(PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold),
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'ابحث عن وظيفة، مهنة، شركة...',
                  style:
                      TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  PhosphorIcons.slidersHorizontal(PhosphorIconsStyle.bold),
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _banner(BannerModel banner, int totalOffers) => Container(
        height: 146,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: const LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [Color(0xFF062A63), Color(0xFF2F6FED)],
          ),
          boxShadow: AppShadows.colored(AppColors.primary, opacity: 0.26),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              left: -14,
              bottom: -20,
              child: Icon(
                PhosphorIcons.hardHat(PhosphorIconsStyle.fill),
                size: 132,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: 0.12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 215,
                    child: Text(
                      banner.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (banner.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      banner.subtitle!,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 12),
                  PressableScale(
                    onTap: _openSearch,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        boxShadow:
                            AppShadows.colored(AppColors.gold, opacity: 0.34),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            banner.ctaLabel ?? 'اكتشف $totalOffers عرض عمل',
                            style: const TextStyle(
                              color: Color(0xFF3D2E00),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(
                            PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                            size: 13,
                            color: const Color(0xFF3D2E00),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  /// المداخل الستة المختصرة — 3.2
  Widget _tiles(bool isCompany) {
    final tiles = <_Tile>[
      _Tile('البحث عن عمل', PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold),
          AppColors.tileGreen, _openSearch),
      _Tile('سيرتي الذاتية', PhosphorIcons.fileText(PhosphorIconsStyle.fill),
          AppColors.tileBlue, () {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const CvScreen()));
      }),
      _Tile('الشركات', PhosphorIcons.buildings(PhosphorIconsStyle.fill),
          AppColors.tilePurple, () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CompaniesScreen()));
      }),
      _Tile('وظائف حسب الولاية', PhosphorIcons.mapPin(PhosphorIconsStyle.fill),
          AppColors.tileOrange, () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const WilayaJobsScreen()));
      }),
      _Tile('العروض المميّزة', PhosphorIcons.star(PhosphorIconsStyle.fill),
          AppColors.tileRed, () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const JobsListScreen(featuredOnly: true)),
        );
      }),
      isCompany
          ? _Tile('عروضي', PhosphorIcons.folderOpen(PhosphorIconsStyle.fill),
              AppColors.tileTeal, () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MyJobsScreen()));
            })
          : _Tile(
              'العروض المحفوظة',
              PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill),
              AppColors.tileTeal, () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SavedScreen()));
            }),
    ];

    if (isCompany) {
      tiles.insert(
        2,
        _Tile('نشر عرض عمل', PhosphorIcons.plusCircle(PhosphorIconsStyle.fill),
            AppColors.tileTeal, () {
          Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PostJobScreen()))
              .then((_) => _reload());
        }),
      );
    }

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.92,
      children: tiles.take(6).map(_tileCard).toList(),
    );
  }

  Widget _tileCard(_Tile tile) => PressableScale(
        onTap: tile.onTap,
        scale: 0.94,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      tile.color,
                      Color.lerp(tile.color, Colors.black, 0.18)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: AppShadows.colored(tile.color, opacity: 0.30),
                ),
                child: Icon(tile.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  tile.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _sectionHeader(String title, IconData icon, Color color,
          {VoidCallback? onSeeAll}) =>
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 9),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(44, 36),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('عرض الكل', style: TextStyle(fontSize: 12.5)),
                  const SizedBox(width: 2),
                  Icon(PhosphorIcons.caretLeft(PhosphorIconsStyle.bold),
                      size: 13),
                ],
              ),
            ),
        ],
      );

  Widget _featuredRow(List<JobOffer> offers) => SizedBox(
        height: 142,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 4),
          itemCount: offers.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final o = offers[i];
            return SizedBox(
              width: 240,
              child: PressableScale(
                onTap: () => _openOffer(o),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.38),
                        width: 1.4),
                    boxShadow: AppShadows.card,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CompanyAvatar(
                                company: o.company,
                                sector: o.sector,
                                size: 36),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                o.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const FeaturedBadge(),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Text(
                          o.company?.name ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(PhosphorIcons.money(PhosphorIconsStyle.fill),
                                size: 13, color: AppColors.success),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                o.salaryLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Icon(PhosphorIcons.mapPin(PhosphorIconsStyle.fill),
                                size: 11, color: AppColors.textMuted),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                o.wilaya,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.textMuted),
                              ),
                            ),
                            ContractChip(contractType: o.contractType),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

  Widget _loadingView() => ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 250,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(26)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(
                4,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: JobCardSkeleton(),
                ),
              ),
            ),
          ),
        ],
      );
}

class _Tile {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _Tile(this.label, this.icon, this.color, this.onTap);
}
