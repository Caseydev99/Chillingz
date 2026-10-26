import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/activity_tracking_service.dart';
import '../../../core/services/location_permission_controller.dart';
import '../../../core/utils/extensions.dart';
import '../../../widgets/banner_widget.dart';
import '../../../widgets/content_loading_placeholder.dart';
import '../../../widgets/discover_items_list.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/home_filter_sheet.dart';
import '../../../widgets/home_categories_grid.dart';
import '../../../widgets/home_tabs.dart';
import '../../../widgets/home_top_bar.dart';
import '../../../widgets/location_bar.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/home_category_item.dart';
import '../models/home_discovery_item.dart';
import '../providers/home_provider.dart';
import 'chillingz_content_detail_screen.dart';
import 'chillingz_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _didCheckLocation = false;
  final TextEditingController _homeSearchController = TextEditingController();
  final ScrollController _homeScrollController = ScrollController();
  DateTime _now = DateTime.now();
  Timer? _dateTimer;
  Timer? _searchActivityTimer;

  void _handleForYouRefresh() {
    context.read<HomeProvider>().refreshForYouRecommendations();
    if (!_homeScrollController.hasClients) {
      return;
    }
    _homeScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  void _handleHomeSearchChanged(String value) {
    context.read<HomeProvider>().updateHomeSearchQuery(value);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateCurrentDate();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dateTimer?.cancel();
    _searchActivityTimer?.cancel();
    _homeSearchController.dispose();
    _homeScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateCurrentDate();
    }
  }

  void _updateCurrentDate() {
    final current = DateTime.now();
    if (!mounted) {
      return;
    }
    if (current.day != _now.day ||
        current.month != _now.month ||
        current.year != _now.year) {
      setState(() => _now = current);
    }
  }

  Future<void> _handleCategoryTap(HomeCategoryItem item) async {
    if (item.routeName == null) {
      return;
    }

    await Navigator.pushNamed(context, item.routeName!);
    if (!mounted) {
      return;
    }
    context.read<HomeProvider>().resetHomeFilters();
    _homeSearchController.clear();
  }

  Future<void> _handleDiscoveryTap(HomeDiscoveryItem item) async {
    final destination = context.read<HomeProvider>().discoveryDestination(item);
    final contentItems = item.contentItems;
    if (destination != null) {
      await Navigator.pushNamed(
        context,
        destination.routeName,
        arguments: destination.arguments,
      );
    } else {
      // This branch pushes the screen directly instead of going through the
      // router, so the view is recorded here.
      ActivityTrackingService.instance.trackActivityInBackground(
        action: contentItems.length == 1
            ? ActivityActions.listingView
            : ActivityActions.categoryView,
        item: contentItems.length == 1 ? contentItems.first.title : item.title,
        category: AppStrings.chillingzForYou,
      );
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => contentItems.length == 1
              ? ChillingzContentDetailScreen(
                  item: contentItems.first,
                  fallbackImage: item.imagePath,
                )
              : ChillingzDetailScreen(item: item),
        ),
      );
    }
    if (!mounted) {
      return;
    }
    context.read<HomeProvider>().resetHomeFilters();
    _homeSearchController.clear();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didCheckLocation) {
      return;
    }

    _didCheckLocation = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      final provider = context.read<HomeProvider>();
      provider.loadPublicData();
      await provider.initializeLocation();

      // Re-check state without pushing a route. Permission changes are shown
      // inline as "Not specified" and can be managed from Profile settings.
      await LocationPermissionController.instance.refresh(enforce: false);
    });
  }

  Future<void> _showHomeFilterSheet() async {
    final provider = context.read<HomeProvider>();
    final isCategoriesTab = provider.selectedTabIndex == 0;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => HomeFilterSheet(
        title: AppStrings.filterHome,
        filters: isCategoriesTab
            ? provider.homeCategoryFilters
            : provider.homeDiscoveryFilters,
        selectedFilter: isCategoriesTab
            ? provider.selectedHomeCategoryFilter
            : provider.selectedHomeDiscoveryFilter,
        onSelected: isCategoriesTab
            ? provider.updateHomeCategoryFilter
            : provider.updateHomeDiscoveryFilter,
        onReset: provider.resetHomeFilters,
      ),
    );

    if (!mounted) {
      return;
    }

    final updatedQuery = context.read<HomeProvider>().homeSearchQuery;
    if (_homeSearchController.text != updatedQuery) {
      _homeSearchController.value = _homeSearchController.value.copyWith(
        text: updatedQuery,
        selection: TextSelection.collapsed(offset: updatedQuery.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = context.isSmallPhone ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                8,
                horizontalPadding,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HomeTopBar(),
                  18.vSpace,
                  const LocationBar(),
                  16.vSpace,
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return _UserGreetingTitle(
                        authProvider: authProvider,
                        builder: (title) {
                          return BannerWidget(
                            title: title,
                            subtitle: _formatHomeDate(_now),
                            searchHint: AppStrings.homeSearchHint,
                            searchController: _homeSearchController,
                            onSearchChanged: _handleHomeSearchChanged,
                            onFilterTap: _showHomeFilterSheet,
                          );
                        },
                      );
                    },
                  ),
                  18.vSpace,
                  Consumer<HomeProvider>(
                    builder: (context, provider, child) {
                      return HomeTabs(
                        selectedIndex: provider.selectedTabIndex,
                        onChanged: provider.updateTab,
                      );
                    },
                  ),
                ],
              ),
            ),
            16.vSpace,
            Expanded(
              child: Consumer<HomeProvider>(
                builder: (context, provider, child) {
                  final categoryItems = provider.filteredCategoryItems;
                  final discoveryItems = provider.filteredDiscoveryItems;
                  return SingleChildScrollView(
                    controller: _homeScrollController,
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      0,
                      horizontalPadding,
                      16,
                    ),
                    child: provider.selectedTabIndex == 0
                        ? categoryItems.isEmpty
                              ? provider.isLoadingPublicData
                                    ? const ContentLoadingPlaceholder(
                                        itemCount: 6,
                                        grid: true,
                                      )
                                    : EmptyState(
                                        message: AppStrings.currentlyUnavailable,
                                        icon: Icons.grid_view_outlined,
                                        actionLabel:
                                            provider.publicDataError == null
                                            ? null
                                            : 'Retry',
                                        onAction:
                                            provider.publicDataError == null
                                            ? null
                                            : () => provider.loadPublicData(
                                                forceRefresh: true,
                                              ),
                                      )
                              : HomeCategoriesGrid(
                                  items: categoryItems,
                                  onItemTap: _handleCategoryTap,
                                )
                        : discoveryItems.isEmpty
                        ? provider.isLoadingPublicData
                              ? const ContentLoadingPlaceholder(itemCount: 4)
                              : EmptyState(
                                  message: AppStrings.currentlyUnavailable,
                                  icon: Icons.auto_awesome_outlined,
                                  actionLabel: provider.publicDataError == null
                                      ? null
                                      : 'Retry',
                                  onAction: provider.publicDataError == null
                                      ? null
                                      : () => provider.loadPublicData(
                                          forceRefresh: true,
                                        ),
                                )
                        : Column(
                            children: [
                              DiscoverItemsList(
                                items: discoveryItems,
                                refreshToken: provider.forYouRefreshToken,
                                onItemTap: _handleDiscoveryTap,
                              ),
                              20.vSpace,
                              Center(
                                child: _ForYouRefreshButton(
                                  onTap: _handleForYouRefresh,
                                ),
                              ),
                            ],
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatHomeDate(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }
}

class _ForYouRefreshButton extends StatelessWidget {
  const _ForYouRefreshButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.primaryButtonGradient,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.rs(22, min: 18, max: 26),
              vertical: context.rs(13, min: 11, max: 15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.refresh_rounded,
                  size: context.rs(20, min: 18, max: 22),
                  color: AppColors.white,
                ),
                8.hSpace,
                Text(
                  'Refresh',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: context.rs(15, min: 14, max: 16),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserGreetingTitle extends StatelessWidget {
  const _UserGreetingTitle({required this.authProvider, required this.builder});

  final AuthProvider authProvider;
  final Widget Function(String title) builder;

  @override
  Widget build(BuildContext context) {
    final user = authProvider.currentUser;
    if (user == null) {
      return builder('Hi there');
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final firestoreName = data?['name']?.toString().trim() ?? '';
        final fallbackName = user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : (user.email?.split('@').first.trim() ?? '');
        final name = firestoreName.isNotEmpty ? firestoreName : fallbackName;

        return builder(name.isEmpty ? 'Hi there' : 'Hi $name');
      },
    );
  }
}
