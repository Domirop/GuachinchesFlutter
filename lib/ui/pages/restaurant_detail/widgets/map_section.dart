import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:maps_launcher/maps_launcher.dart';

class MapSection extends StatelessWidget {
  final Restaurant restaurant;

  const MapSection({super.key, required this.restaurant});

  static const _darkStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1a2535"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#339ED0"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0A0F14"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0A0F14"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#243348"}]}
]
''';

  void _openNative() {
    if (restaurant.lat != 0 && restaurant.lon != 0) {
      MapsLauncher.launchCoordinates(
        restaurant.lat,
        restaurant.lon,
        restaurant.nombre,
      );
    } else {
      MapsLauncher.launchQuery(restaurant.nombre);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCoords = restaurant.lat != 0 && restaurant.lon != 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            SizedBox(
              height: 140,
              child: GestureDetector(
                onTap: _openNative,
                child: hasCoords
                    ? AbsorbPointer(
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(restaurant.lat, restaurant.lon),
                            zoom: 15,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('r'),
                              position:
                                  LatLng(restaurant.lat, restaurant.lon),
                            ),
                          },
                          liteModeEnabled: true,
                          zoomControlsEnabled: false,
                          myLocationButtonEnabled: false,
                          onMapCreated: (c) {
                            c.setMapStyle(_darkStyle);
                          },
                        ),
                      )
                    : Container(
                        color: context.brand.elevated,
                        alignment: Alignment.center,
                        child: Icon(Icons.map_outlined,
                            color: context.brand.textMuted, size: 32),
                      ),
              ),
            ),
            Container(
              color: context.brand.surface,
              padding: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      restaurant.direccion,
                      style: AppTextStyles.ui(
                        size: 10,
                        color: context.brand.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _openNative,
                    child: Text(
                      'Abrir en Maps →',
                      style: AppTextStyles.ui(
                        size: 10,
                        weight: FontWeight.w600,
                        color: AppColors.atlanticoClaro,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
