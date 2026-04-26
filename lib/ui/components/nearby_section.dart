import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/location/location_state.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/components/cards/nearby_restaurant_card.dart';
import 'package:guachinches/ui/components/section_header.dart';
import 'package:guachinches/utils/distance_utils.dart';

class NearbySection extends StatelessWidget {
  final List<NearbyRestaurant> restaurants;
  final bool isLoadingRestaurants;

  const NearbySection({
    Key? key,
    required this.restaurants,
    required this.isLoadingRestaurants,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationCubit, LocationState>(
      builder: (context, locationState) {
        // Nothing to show until we have a confirmed GPS fix.
        // During LocationLoading the presenter hasn't been called yet — showing
        // a shimmer here would be misleading and could last up to 30 seconds.
        if (locationState is LocationInitial ||
            locationState is LocationLoading ||
            locationState is LocationUnavailable) {
          return const SizedBox.shrink();
        }

        // User explicitly denied permission → actionable banner.
        if (locationState is LocationDenied) {
          return _buildPermissionBanner();
        }

        // locationState is LocationLoaded from here on.
        // Only show the shimmer when the nearby API call is actually in flight.
        if (!isLoadingRestaurants && restaurants.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: '📍 Cerca de ti'),
            isLoadingRestaurants ? _shimmerRow() : _buildList(),
          ],
        );
      },
    );
  }

  Widget _buildPermissionBanner() {
    return GestureDetector(
      onTap: () => Geolocator.openAppSettings(),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: GlobalMethods.bgColorFilter,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_off_rounded, color: Colors.white54, size: 22),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Para ver restaurantes cercanos, danos permisos de ubicación',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontFamily: 'SF Pro Display',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Activar',
              style: TextStyle(
                color: GlobalMethods.blueColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'SF Pro Display',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        itemCount: restaurants.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: NearbyRestaurantCard(
              restaurant: restaurants[index].restaurant,
              distance: restaurants[index].distanceLabel,
              typeName: restaurants[index].typeName,
            ),
          );
        },
      ),
    );
  }

  Widget _shimmerRow() {
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        itemCount: 3,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            width: 240,
            height: 250,
            decoration: BoxDecoration(
              color: GlobalMethods.bgColorFilter,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}
