import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_state.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/components/cards/TopRestaurantListCard.dart';
import 'package:guachinches/ui/components/cards/restaurantMainCard.dart';
import 'package:guachinches/ui/components/filters/filterBar.dart';
import 'package:location/location.dart';

class MapSearch extends StatefulWidget {
  const MapSearch({Key? key}) : super(key: key);

  @override
  State<MapSearch> createState() => MapSearchState();
}

class MapSearchState extends State<MapSearch> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  String lastMarkerId = "";
  final PageController _pageController = PageController();
  late LatLng currentLocation = LatLng(28.4495292, -16.4206765);
  CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(28.4495292, -16.4206765),
    zoom: 14.4746,
  );

  Set<Marker> markers = {};
  bool isFirst = true;
  List<Restaurant> visibleRestaurants = [];

  // Variable para mantener el estado de la tarjeta
  String _cardTitle = "Tarjeta por defecto";

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      Location location = new Location();

      bool _serviceEnabled;
      PermissionStatus _permissionGranted;
      LocationData _locationData;

      _serviceEnabled = await location.serviceEnabled();

      if (!_serviceEnabled) {
        _serviceEnabled = await location.requestService();
        if (!_serviceEnabled) {
          return;
        }
      }

      _permissionGranted = await location.hasPermission();

      if (_permissionGranted == PermissionStatus.denied) {
        _permissionGranted = await location.requestPermission();
        if (_permissionGranted != PermissionStatus.granted) {
          return;
        }
      }
      _locationData = await location.getLocation();
      print(_locationData.latitude.toString() +
          " " +
          _locationData.longitude.toString());
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(_locationData.latitude!, _locationData.longitude!),
        zoom: 14.4746,
      )));
      setState(() {
        currentLocation =
            LatLng(_locationData.latitude!, _locationData.longitude!);
      });
    } catch (e) {
      print("Error obtaining location: $e");
    }
  }

  final controller = DraggableScrollableController();

  @override
  Widget build(BuildContext context) {
    _getLocation();
    return Scaffold(
      body: BlocBuilder<RestaurantCubit, RestaurantState>(
          builder: (context, state) {
        Set<Marker> aux = {};
        if (currentLocation is LatLng) {
          aux.add(Marker(
            markerId: MarkerId("currentLocation"),
            position: currentLocation,
            infoWindow: InfoWindow(title: "Tu ubicación"),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ));
        }
        List<Restaurant> restaurants = [];
        if (state is AllRestaurantLoaded) {
          print(
              "mapa " + state.restaurantResponse.restaurants.length.toString());
          restaurants = state.restaurantResponse.restaurants;
          state.restaurantResponse.restaurants.forEach((element) {
            aux.add(Marker(
              markerId: MarkerId(element.id.toString()),
              position: LatLng(element.lat, element.lon),
              infoWindow: InfoWindow(title: element.nombre),
              onTap: () => _onMarkerTapped(element.id.toString()),
            ));
          });
          markers = aux;
          if (isFirst) {
            getVisibleMarkers(restaurants);
            isFirst = false;
          }
        }else if(state is RestaurantFilter){

          restaurants = state.filtersRestaurants;
          state.filtersRestaurants.forEach((element) {
            aux.add(Marker(
              markerId: MarkerId(element.id.toString()),
              position: LatLng(element.lat, element.lon),
              infoWindow: InfoWindow(title: element.nombre),
              onTap: () => _onMarkerTapped(element.id.toString()),
            ));
          });
          markers = aux;
          if (isFirst) {
            getVisibleMarkers(restaurants);
            isFirst = false;
          }
        }

        return Stack(
          children: [
            GoogleMap(
              mapType: MapType.hybrid,
              onCameraMove: (CameraPosition position) {
                getVisibleMarkers(restaurants);
              },
              initialCameraPosition: _kGooglePlex,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              markers: aux,
              onTap: (_) {
                // Limpiar la tarjeta cuando se toque en cualquier lugar del mapa
                _updateCardTitle("Tarjeta por defecto");
              },
            ),
            Padding(
              padding: const EdgeInsets.only(top: 64.0, left: 8),
              child: Container(
                height: 30,
                child: FilterBar(
                  categories: [],
                  showCategoryChip: true,
                  municipalities: [],
                  types: [],
                ),
              ),
            ),
            Positioned(
              bottom: 86,
              left: 16,
              right: 16,
              child: Container(
                height: 132, // Altura fija para las tarjetas
                child: PageView.builder(
                  controller: _pageController,
                  physics: PageScrollPhysics(),
                  // Permite el desplazamiento página por página
                  scrollDirection: Axis.horizontal,
                  onPageChanged: (index) async {
                    final GoogleMapController controller =
                        await _controller.future;
                    MarkerId markerId =
                        MarkerId(visibleRestaurants[index].id.toString());
                    controller.showMarkerInfoWindow(markerId);
                    // Actualizar el marcador cuando se cambie de página
                  },
                  itemCount: visibleRestaurants.length,
                  itemBuilder: (context, index) {
                    TopRestaurants topRestaurant = new TopRestaurants(
                      nombre: visibleRestaurants[index].nombre,
                      open: visibleRestaurants[index].open,
                      id: visibleRestaurants[index].id,
                      horarios: visibleRestaurants[index].horarios,
                      direccion: visibleRestaurants[index].direccion,
                      counter: visibleRestaurants[index].avgRating.toString(),
                      imagen: visibleRestaurants[index].mainFoto,
                      cerrado: visibleRestaurants[index].open.toString(),
                      municipio: visibleRestaurants[index].municipio,
                      avg: visibleRestaurants[index].avgRating,
                    );
                    return GestureDetector(
                      child: Container(
                        width: MediaQuery.of(context).size.width - 32,
                        // Ancho igual al ancho de la pantalla menos el margen
                        margin: EdgeInsets.only(right: 16),
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TopRestaurantListCard(topRestaurant),
                      ),
                    );
                  },
                ),
              ),
            ),
            DraggableScrollableSheet(
              controller: controller,
              initialChildSize: 0.1,
              minChildSize: 0.1,
              maxChildSize: 0.82,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.0),
                      topRight: Radius.circular(20.0),
                    ),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Center(
                          child: Container(
                            height: 2,
                            color: Color.fromRGBO(231, 231, 231, 1),
                            width: 64,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: GestureDetector(
                          onTap: () => {
                            controller.animateTo(
                              0.82,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInBack,
                            )
                          },
                          child: Text(
                            'Mostrar la lista de Restaurantes',
                            style: TextStyle(
                              fontSize: 16.0,
                              color: Color.fromRGBO(0, 133, 196, 1),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: visibleRestaurants.length,
                            itemBuilder: (BuildContext context, int index) {
                              return RestaurantMainCard(
                                restaurant: visibleRestaurants[index],
                                size: 'big',
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      }),
    );
  }

  void _onMarkerTapped(String markerId) {
    // Actualizar la tarjeta cuando se haga clic en un marcador
    _updateCardTitle("Tarjeta para $markerId");
    int index = visibleRestaurants
        .indexWhere((restaurant) => restaurant.id == markerId);

    print('Marker Tapped' + markerId.toString());
    _pageController.animateToPage(index,
        duration: Duration(milliseconds: 500), curve: Curves.ease);
    // getVisibleMarkers();
    lastMarkerId = markerId;
  }

  Future<void> getVisibleMarkers(List<Restaurant> restaurants) async {
    final GoogleMapController controller = await _controller.future;

    LatLngBounds bounds = await controller.getVisibleRegion();

    List<Marker> visibleMarkers = markers.where((marker) {
      return bounds.contains(marker.position);
    }).toList();
    // Hacer algo con los marcadores visibles, como imprimir sus títulos

    setState(() {
      visibleRestaurants = restaurants.where((element) {
        // Filtra los restaurantes cuyos marcadores están dentro de los límites visibles
        return visibleMarkers.any(
            (marker) => marker.position == LatLng(element.lat, element.lon));
      }).toList();
    });

    _onMarkerTapped(lastMarkerId);
  }

  void _updateCardTitle(String title) {
    setState(() {
      _cardTitle = title;
    });
  }
}
