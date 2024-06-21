import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_state.dart';
import 'package:guachinches/data/cubit/restaurants/map/restaurant_map_cubit.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/Municipality.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/data/model/Types.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/components/cards/TopRestaurantListCard.dart';
import 'package:guachinches/ui/components/cards/restaurantMainCard.dart';
import 'package:guachinches/ui/components/filters/filterBar.dart';
import 'package:guachinches/ui/components/filters/filterBarMap.dart';
import 'package:guachinches/ui/pages/map/map_search_presenter.dart';
import 'package:http/http.dart';
import 'package:location/location.dart';
import 'package:flutter/services.dart';

import '../../../data/cubit/restaurants/map/restaurant_map_state.dart';

class MapSearch extends StatefulWidget {
  const MapSearch({Key? key}) : super(key: key);

  @override
  State<MapSearch> createState() => MapSearchState();
}

class MapSearchState extends State<MapSearch> implements MapSearchView {
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
  late RemoteRepository remoteRepository;
  late RestaurantMapCubit restaurantsCubit;
  List<ModelCategory> categories = [];
  bool isFirstMap = true;
  List<Municipality> municipalities = [];
  List<Types> types = [];

  // Variable para mantener el estado de la tarjeta
  String _cardTitle = "Tarjeta por defecto";
  late MapSearchPresenter presenter;
  double appbarSize = 0.08;
  double offsetVisibility = 100.0;
  bool FAB_visibility = true;

  @override
  void initState() {
    remoteRepository = HttpRemoteRepository(Client());
    restaurantsCubit = context.read<RestaurantMapCubit>();
    presenter = MapSearchPresenter(this, remoteRepository, restaurantsCubit);
    super.initState();
    presenter.getAllRestaurants();
    presenter.getAllTypes();
    presenter.getAllMunicipalities('76ac0bec-4bc1-41a5-bc60-e528e0c12f4d');
    presenter.getAllCategories();
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
      if (isFirstMap) {
        isFirstMap = false;
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: LatLng(_locationData.latitude!, _locationData.longitude!),
          zoom: 14.4746,
        )));
        setState(() {
          currentLocation =
              LatLng(_locationData.latitude!, _locationData.longitude!);
        });
      }
    } catch (e) {
      print("Error obtaining location: $e");
    }
  }

  final controller = DraggableScrollableController();

  @override
  Widget build(BuildContext context) {
    _getLocation();
    return Scaffold(
      body: BlocBuilder<RestaurantMapCubit, RestaurantMapState>(
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
        if (state is AllRestaurantMapLoaded) {
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
        }
        if (state is RestaurantFilterMap) {
          print('Filter ' + state.filtersRestaurants.length.toString());
          restaurants = state.filtersRestaurants;
          state.filtersRestaurants.forEach((element) {
            aux.add(Marker(
              markerId: MarkerId(element.id.toString()),
              position: LatLng(element.lat, element.lon),
              infoWindow: InfoWindow(title: element.nombre),
              onTap: () => _onMarkerTapped(element.id.toString()),
            ));
          });
          print('aux ' + aux.length.toString());
          markers = aux;
          if (isFirst) {
            getVisibleMarkers(restaurants);
            isFirst = false;
          }
        }

        return Stack(
          children: [
            GoogleMap(
              mapType: MapType.normal,
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
              child: FilterBarMap(
                filterMap: true,
                zoomOut: () {
                  _zoomOut();
                },
                categories: categories,
                showCategoryChip: true,
                withSearchBar: true,
                municipalities: municipalities,
                types: types,
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
                          color: GlobalMethods.bgColor,
                          borderRadius: BorderRadius.circular(16),
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
            // _buildDiscoverDrawer()
            // En el cuerpo del widget
            NotificationListener<DraggableScrollableNotification>(
              onNotification: (DraggableScrollableNotification DSNotification) {
                if (DSNotification.extent == DSNotification.maxExtent) {
                  HapticFeedback.lightImpact();
                } else if (DSNotification.extent == DSNotification.minExtent) {
                  HapticFeedback.lightImpact();
                }
                return false;
              },
              child: DraggableScrollableSheet(
                initialChildSize: 0.1,
                minChildSize: 0.1,
                controller: controller,
                maxChildSize: 0.82,
                builder:
                    (BuildContext context, ScrollController scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.0),
                        topRight: Radius.circular(20.0),
                      ),
                      color: GlobalMethods.bgColor,
                    ),
                    child: CustomScrollView(
                      controller: scrollController,
                      slivers: [
                        SliverAppBar(
                          toolbarHeight: 24,
                          backgroundColor:GlobalMethods.bgColor,
                          elevation: 0,
                          flexibleSpace: FlexibleSpaceBar(
                            centerTitle: true,
                            titlePadding: EdgeInsets.only(top: 16),
                            title: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container(
                                  height: 2,
                                  color: Colors.white,
                                  width: 64,
                                ),
                                GestureDetector(
                                  onTap: () {
                                    controller.animateTo(
                                      0.80,
                                      duration:
                                          const Duration(milliseconds: 200),
                                      curve: Curves.easeInBack,
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      'Mostrar la lista de Restaurantes',
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontFamily: 'SF Pro Display',
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          pinned: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                        ),
                        SliverFixedExtentList(
                          itemExtent: 300,
                          delegate: SliverChildBuilderDelegate(
                            (BuildContext context, int index) {
                              return Center(
                                child: RestaurantMainCard(
                                  restaurant: visibleRestaurants[index],
                                  size: 'big',
                                ),
                              );
                            },
                            childCount: visibleRestaurants.length,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildDiscoverDrawer() {
    return DraggableScrollableSheet(
        maxChildSize: 0.95,
        minChildSize: 0.25,
        initialChildSize: 0.4,
        builder: (context, scrollController) {
          List<Widget> _sliverList(int size, int sliverChildCount) {
            List<Widget> widgetList = [];
            for (int index = 0; index < size; index++)
              widgetList
                ..add(SliverAppBar(
                  title: GestureDetector(
                      onTap: () {
                        print('gol');
                      },
                      child: Text("Title $index")),
                  pinned: true,
                ))
                ..add(SliverFixedExtentList(
                  itemExtent: 50.0,
                  delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                    return Container(
                      alignment: Alignment.center,
                      color: Colors.lightBlue[100 * (index % 9)],
                      child: Text('list item $index'),
                    );
                  }, childCount: sliverChildCount),
                ));

            return widgetList;
          }

          return Container(
            color: Colors.white,
            child: CustomScrollView(
              controller: scrollController,
              slivers: _sliverList(1, 10),
            ),
          );
        });
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

  @override
  setCategories(List<ModelCategory> categories) {
    setState(() {
      this.categories = categories;
    });
  }

  @override
  setMunicipalities(List<Municipality> municipalities) {
    setState(() {
      this.municipalities = municipalities;
    });
  }

  @override
  setTypes(List<Types> types) {
    setState(() {
      this.types = types;
    });
  }

  Future<void> _zoomOut() async {
    print('zoom');
    final GoogleMapController mapController = await _controller.future;
    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(28.291565, -16.629129),
        9.5, // Ajusta el nivel de zoom según sea necesario
      ),
    );
  }
}
