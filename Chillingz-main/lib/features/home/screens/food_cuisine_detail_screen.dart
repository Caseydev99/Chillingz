import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_values.dart';
import '../../../core/utils/extensions.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/app_screen_header.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/saved_detail_card.dart';
import '../models/food_cuisine_item.dart';
import '../models/saved_detail_item.dart';
import '../providers/home_provider.dart';

class FoodCuisineDetailScreen extends StatelessWidget {
  const FoodCuisineDetailScreen({super.key, required this.item});

  final FoodCuisineItem item;

  void _openPlace(BuildContext context, SavedDetailItem place) {
    Navigator.pushNamed(context, AppRoutes.foodPlaceDetail, arguments: place);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        final places = provider.foodCuisinePlacesForItem(item);

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppValues.screenHorizontalPadding,
                10,
                AppValues.screenHorizontalPadding,
                20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppScreenHeader(title: item.title),
                  16.vSpace,
                  if (places.isEmpty)
                    EmptyState(
                      message: AppStrings.currentlyUnavailable,
                      icon: Icons.local_dining_outlined,
                    )
                  else
                    ...places.map((place) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: context.rs(10, min: 10, max: 12),
                        ),
                        child: SavedDetailCard(
                          item: place,
                          isLiked: provider.isSavedItemLiked(place.id),
                          isLikePending: provider.isSavedItemPending(place.id),
                          onLikeTap: () =>
                              provider.toggleSavedItemLike(place.id),
                          onTap: () => _openPlace(context, place),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
