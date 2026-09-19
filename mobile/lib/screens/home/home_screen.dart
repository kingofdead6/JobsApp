import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';
import '../company/post_job_screen.dart';
import '../company/my_jobs_screen.dart';
import '../jobs/job_detail_screen.dart';
import '../jobs/jobs_list_screen.dart';
import '../jobs/wilaya_jobs_screen.dart';
import '../company/companies_screen.dart';
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

  void _openSearch({String? query}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => JobsListScreen(initialQuery: query)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isCompany = auth.isCompany;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _reload,
          child: FutureBuilder<Map<String, dynamic>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return _loadingView();
              }
              if (snap.hasError) {
                return ListView(
                  children: [
                    const SizedBox(height: 100),
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
                  SliverToBoxAdapter(child: _header(auth)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (banners.isNotEmpty) ...[
                            _banner(banners.first, total),
                            const SizedBox(height: 16),
                          ],
                          _searchBar(),
                          const SizedBox(height: 18),
                          _tiles(isCompany),
                          const SizedBox(height: 22),
                          if (featured.isNotEmpty) ...[
                            _sectionHeader(
                              'العروض المميّزة',
                              onSeeAll: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const JobsListScreen(featuredOnly: true),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _featuredRow(featured),
                            const SizedBox(height: 22),
                          ],
                          _sectionHeader(
                            'أحدث عروض العمل',
                            onSeeAll: () => _openSearch(),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                  if (latest.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: EmptyState(
                          icon: Icons.work_off_rounded,
                          title: 'لا توجد عروض منشورة بعد',
                          subtitle: 'عُد لاحقًا، تُضاف عروض جديدة يوميًا',
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList.separated(
                        itemCount: latest.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => JobCard(
                          offer: latest[i],
                          onTap: () => _openOffer(latest[i]),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _openOffer(JobOffer offer) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => JobDetailScreen(offerId: offer.id)),
    ).then((_) => _reload());
  }

  Widget _header(AuthProvider auth) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_search_rounded, color: Colors.white, size: 26),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                children: [
                  TextSpan(text: 'بحث عن ', style: TextStyle(color: Colors.white)),
                  TextSpan(text: 'عمل', style: TextStyle(color: AppColors.gold)),
                  TextSpan(
                    text: '  DZ',
                    style: TextStyle(color: AppColors.gold, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => widget.onNavigateTab?.call(3),
              icon: const Icon(Icons.notifications_none_rounded,
                  color: Colors.white),
              tooltip: 'الإشعارات',
            ),
          ],
        ),
      );

  Widget _banner(BannerModel banner, int totalOffers) => Container(
        height: 132,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [AppColors.primaryDark, AppColors.primaryLight],
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              left: -10,
              bottom: -14,
              child: Icon(
                Icons.engineering_rounded,
                size: 118,
                color: Colors.white.withValues(alpha: 0.13),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 210,
                    child: Text(
                      banner.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _openSearch(),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        banner.ctaLabel ?? 'اكتشف $totalOffers عرض عمل',
                        style: const TextStyle(
                          color: Color(0xFF3D2E00),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _searchBar() => GestureDetector(
        onTap: () => _openSearch(),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.search_rounded, color: AppColors.textMuted),
              SizedBox(width: 10),
              Text(
                'ابحث عن وظيفة، مهنة، شركة...',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
              ),
            ],
          ),
        ),
      );

  /// المداخل الستة المختصرة — 3.2
  Widget _tiles(bool isCompany) {
    final tiles = <_Tile>[
      _Tile('البحث عن عمل', Icons.search_rounded, AppColors.tileGreen,
          () => _openSearch()),
      _Tile('سيرتي الذاتية', Icons.description_rounded, AppColors.tileBlue, () {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const CvScreen()));
      }),
      _Tile('الشركات', Icons.business_rounded, AppColors.tilePurple, () {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const CompaniesScreen()));
      }),
      _Tile('وظائف حسب الولاية', Icons.location_on_rounded, AppColors.tileOrange,
          () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const WilayaJobsScreen()));
      }),
      _Tile('العروض المميّزة', Icons.star_rounded, AppColors.tileRed, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const JobsListScreen(featuredOnly: true)),
        );
      }),
      // المدخل السادس يتغيّر حسب نوع الحساب
      isCompany
          ? _Tile('عروضي', Icons.folder_shared_rounded, AppColors.tileTeal, () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MyJobsScreen()));
            })
          : _Tile('العروض المحفوظة', Icons.bookmark_rounded, AppColors.tileTeal,
              () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SavedScreen()));
            }),
    ];

    // مدخل «نشر عرض عمل» للمؤسسات فقط
    if (isCompany) {
      tiles.insert(
        2,
        _Tile('نشر عرض عمل', Icons.add_circle_rounded, AppColors.tileTeal, () {
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
      childAspectRatio: 0.96,
      children: tiles.take(6).map((t) => _tileCard(t)).toList(),
    );
  }

  Widget _tileCard(_Tile tile) => InkWell(
        onTap: tile.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: tile.color,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(tile.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  tile.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _sectionHeader(String title, {VoidCallback? onSeeAll}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(44, 36),
              ),
              child: const Text('عرض الكل', style: TextStyle(fontSize: 13)),
            ),
        ],
      );

  Widget _featuredRow(List<JobOffer> offers) => SizedBox(
        height: 128,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: offers.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final o = offers[i];
            return SizedBox(
              width: 230,
              child: Card(
                child: InkWell(
                  onTap: () => _openOffer(o),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CompanyAvatar(
                                company: o.company, sector: o.sector, size: 34),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                o.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          o.company?.name ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                        const Spacer(),
                        Text(
                          o.salaryLabel,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                o.wilaya,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textMuted),
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
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 60),
          ...List.generate(
            5,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: JobCardSkeleton(),
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
