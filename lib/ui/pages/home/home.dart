import 'dart:async';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/cubit/banners/banners_cubit.dart';
import 'package:guachinches/data/cubit/banners/banners_state.dart';
import 'package:guachinches/data/cubit/cupones/cupones_cubit.dart';
import 'package:guachinches/data/cubit/filter/filter_cubit.dart';
import 'package:guachinches/data/cubit/filter/filter_state.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/location/location_state.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/utils/distance_utils.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_state.dart';
import 'package:guachinches/data/cubit/restaurants/top/top_restaurant_state.dart';
import 'package:guachinches/data/cubit/restaurants/top/top_restaurants_cubit.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/CuponesAgrupados.dart';
import 'package:guachinches/data/model/Municipality.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/data/model/Types.dart';
import 'package:guachinches/data/model/Video.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/blog_post.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/components/SurveyResults/SurveyResults.dart';
import 'package:guachinches/ui/components/app_Bars/appbar_basic.dart';
import 'package:guachinches/ui/components/banner/banner_ad.dart';
import 'package:guachinches/ui/components/blog_post/blog_post_component.dart';
import 'package:guachinches/ui/components/cards/rankingCard.dart';
import 'package:guachinches/ui/components/cards/restaurantMainCard.dart';
import 'package:guachinches/ui/components/cards/surveyCard.dart';
import 'package:guachinches/ui/components/cards/topRestaurantCard.dart';
import 'package:guachinches/ui/components/cards/restaurantOpenCard.dart';
import 'package:guachinches/ui/components/categories/CategoryImageCard.dart';
import 'package:guachinches/ui/components/heroSliderComponent.dart';
import 'package:guachinches/ui/components/nearby_section.dart';
import 'package:guachinches/ui/components/rankingList.dart';
import 'package:guachinches/ui/components/survey_banner/survey_banner.dart';
import 'package:guachinches/ui/components/survey_popup/survey_popup.dart';
import 'package:guachinches/ui/components/visit/visit_list.dart';
import 'package:guachinches/ui/pages/advance_search/advanced_search.dart';
import 'package:guachinches/ui/pages/changeIsland/change_island.dart';
import 'package:guachinches/ui/pages/home/home_presenter.dart';
import 'package:guachinches/ui/pages/restaurantList/restaurant_list.dart';
import 'package:guachinches/ui/pages/restaurantsShowMore/restaurantsShowMoreGuachinches.dart';
import 'package:guachinches/ui/pages/surveyRanking/surveyRanking.dart';
import 'package:guachinches/ui/pages/verifiedVisit/verifiedVisitsScreen.dart';
import 'package:guachinches/ui/pages/visit/visit_screen.dart';
import 'package:http/http.dart';

class Home extends StatefulWidget {
  bool isChargingInitalRestaurants = true;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver implements HomeView {
  late AppBarBasic appBarBasic;
  List<String> selectedCategories = [];
  late String islandId = '';
  final PageController _pageController = PageController(viewportFraction: 0.90);
  List<String> selectedMunicipalities = [];
  List<Restaurant> restaurantsFilteredGuachinches = [];
  List<Restaurant> restaurantsFilteredGuachinchesByViews = [];
  List<String> typesSelected = [];
  bool doRequest = false;
  bool isCharging = false;
  int menuRestaurantSelected = 0;
  List<String> menuOptions = ['Top mejores', 'Abiertos'];
  List<Video> videos = [];
  late HomePresenter presenter;
  late List<Widget> screens;
  late RemoteRepository remoteRepository;
  List<ModelCategory> categories = [];
  List<Municipality> municipalities = [];
  List<Types> types = [];
  late bool isCorrectSaveCupon;
  late Widget restaurantsWidgets;
  late Widget openRestaurantsWidgets;
  late Widget menuRestaurants;
  late List<Restaurant> allSurveyRestaurants = [];
  SurveyRanking? surveyRanking;

  late String userId;
  List<String> assets = [
    "assets/images/firstTop.png",
    "assets/images/secondTop.png",
    "assets/images/thirdTop.png",
    "assets/images/otherTop.png",
    "assets/images/otherTop.png"
  ];
  List<CuponesAgrupados> cuponesAgrupados = [];
  List<TopRestaurants> topRestaurants = [];
  bool userIdSearched = false;
  final ScrollController _scrollController = new ScrollController();
  bool showCategoryChip = false;
  late FilterCubit filterCubit;
  late RestaurantCubit restaurantsCubit;


  List<SurveyResult> surveyGuachinchesModernos = [];
  List<SurveyResult> surveyGuachinchesTradicionales = [];
  bool _surveyPreviewIsTraditional = true;
  Timer? _surveyPreviewTimer;
  List<Visit> allVisits = [];
  List<BlogPost> blogPosts = [];
  Color _appBarBackgroundColor = Colors.transparent;
  List<NearbyRestaurant> nearbyRestaurants = [];
  bool _nearbyLoading = false;

  /// Single entry-point for loading nearby restaurants.
  /// Fires only when ALL three dependencies are ready and no request
  /// is already in flight or completed.
  void _tryLoadNearby() {
    final locState = context.read<LocationCubit>().state;

    if (_nearbyLoading || nearbyRestaurants.isNotEmpty) return;
    if (locState is! LocationLoaded) return;
    if (islandId.isEmpty) return;
    // types can be empty — presenter falls back to category names
    setState(() => _nearbyLoading = true);
    presenter.getNearbyRestaurants(
        locState.latitude, locState.longitude, islandId, types);
  }

  @override
  void initState() {
    super.initState();
    final topRestaurantCubit = context.read<TopRestaurantCubit>();
    final cuponesCubit = context.read<CuponesCubit>();
    final bannersCubit = context.read<BannersCubit>();
    final userCubit = context.read<UserCubit>();
    restaurantsCubit = context.read<RestaurantCubit>();
    filterCubit = context.read<FilterCubit>();
    remoteRepository = HttpRemoteRepository(Client());
    presenter = HomePresenter(this, topRestaurantCubit, bannersCubit,
        cuponesCubit, userCubit, remoteRepository, restaurantsCubit);
    presenter.getUserInfo();
    presenter.getCupones();
    presenter.getIsland();
    presenter.getAllVideos();
    presenter.getAllCategories();
    presenter.getAllTypes();
    presenter.getAllVisit();
    presenter.getAllBlogPosts();
    presenter.getTopRestaurants();

    WidgetsBinding.instance.addObserver(this);
    presenter.getSurveyRestaurants();
    context.read<LocationCubit>().requestLocation();

    SurveyPopup.showIfNeeded(
      context,
      onVoted: () => presenter.getSurveyResults(allSurveyRestaurants),
    );

    // Escucha el desplazamiento del scroll para cambiar el fondo de la app bar
    _scrollController.addListener(() {
      if (_scrollController.offset > 50) {
        // Cambiar a color de fondo sólido si se desplaza hacia arriba
        setState(() {
          _appBarBackgroundColor = GlobalMethods.bgColor.withOpacity(0.96);
        });
      } else {
        // Mantener el fondo transparente si está en la parte superior
        setState(() {
          _appBarBackgroundColor = Colors.transparent;
        });
      }
    });

    // context.read<RestaurantCubit>().stream.listen((state) {
    //   if (state is AllRestaurantLoaded) {
    //     setState(() {
    //       allRestaurants = state.restaurantResponse.restaurants;
    //     });
    //   }
    // });

    if (bannersCubit.state is BannersInitial) {
      presenter.getAllBanner();
    }
    if (restaurantsCubit.state is RestaurantInitial ||
        restaurantsCubit.state is RestaurantLoaded) {
      createOpenListWidget();
    }
    if (userCubit.state is UserInitial) {
      presenter.getScreens();
    } else if (userCubit.state is UserLoaded) {
      presenter.getScreens();
    }
  }

  void _onScroll() {
    // Get the scroll offset
    double offset = _scrollController.offset;
    if (offset > 120.0) {
      setState(() {
        showCategoryChip = true;
      });
    } else {
      setState(() {
        showCategoryChip = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _surveyPreviewTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Silent check: no dialogs, just reacts if the user changed permission
      // in Settings while the app was in the background.
      context.read<LocationCubit>().checkLocationSilently();
    }
  }

  Color bgColor = Color.fromRGBO(25, 27, 32, 1);

  // Escucha el desplazamiento del scroll para cambiar el fondo de la app bar

  @override
  Widget build(BuildContext context) {
    return BlocListener<LocationCubit, LocationState>(
      listener: (context, state) {
        if (state is LocationLoaded) _tryLoadNearby();
      },
      child: Scaffold(
      backgroundColor: Color.fromRGBO(25, 27, 32, 1),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // SliverAppBar con barra de búsqueda fija
          SliverAppBar(
            pinned: true,
            floating: false,
            stretch: true,
            snap: false,
            backgroundColor: _appBarBackgroundColor,
            // Fondo dinámico
            elevation: 0,
            expandedHeight: MediaQuery.of(context).size.width * 1.1,
            // Altura dinámica
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Positioned.fill(
                    child: BlocBuilder<BannersCubit, BannersState>(
                      builder: (context, state) {
                        if (state is BannersLoaded) {
                          if (surveyRanking != null) {
                            return HeroSliderComponent(
                              state.banners,
                              surveyRanking: surveyRanking,
                              onVoted: () => presenter.getSurveyResults(allSurveyRestaurants),
                            );
                          }
                          return HeroSliderComponent(
                            state.banners,
                            onVoted: () => presenter.getSurveyResults(allSurveyRestaurants),
                          );
                        } else {
                          return Container();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GestureDetector(
                onTap: () => GlobalMethods().pushPage(
                    context,
                    AdvancedSearch(
                      categories: categories,
                      municipalities: municipalities,
                      types: types,
                      islandId: islandId,
                    )),
                child: Row(
                  children: [
                    // Barra de búsqueda
                    Expanded(
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(50, 43, 45, 1),
                          borderRadius: BorderRadius.circular(20.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10.0,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 16.0),
                            Icon(Icons.search, color: Colors.grey),
                            const SizedBox(width: 8.0),
                            Text(
                              "Busca donde comer",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16.0,
                                fontFamily: 'SF Pro Display',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    // Espacio entre los contenedores
                    // Botón "TF"
                    GestureDetector(
                      onTap: () =>
                          GlobalMethods().pushPage(context, ChangeIsland()),
                      child: Container(
                        height: 36,
                        width: 50, // Ancho del botón
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(50, 43, 45, 1),
                          borderRadius: BorderRadius.circular(20.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10.0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            islandId == "76ac0bec-4bc1-41a5-bc60-e528e0c12f4d"
                                ? "TF"
                                : "GC",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16.0,
                              fontFamily: 'SF Pro Display',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SurveyBanner(
                    onVoted: () => presenter.getSurveyResults(allSurveyRestaurants),
                  ),
                  if (surveyRanking != null &&
                      surveyGuachinchesTradicionales.isNotEmpty)
                    _buildSurveyResultsPreview(),
                  // ── Filtered restaurants ────────────────────────────────
                  // Only mounts when a category/filter is active.
                  // Independent of the home content below.
                  BlocBuilder<FilterCubit, FilterState>(
                    builder: (context, filterState) {
                      if (filterState is! FilterCategory) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        color: Color.fromRGBO(25, 27, 32, 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0),
                          child: BlocBuilder<RestaurantCubit, RestaurantState>(
                            builder: (context, state) {
                              if (state is RestaurantFilter) {
                                return Container(
                                  height: 280 *
                                      state.filtersRestaurants.length
                                          .toDouble(),
                                  child: Column(
                                    children: state.filtersRestaurants
                                        .map((restaurant) => Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 8.0),
                                              child: RestaurantMainCard(
                                                restaurant: restaurant,
                                                size: 'big',
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                );
                              } else if (state is AllRestaurantLoaded) {
                                setAllRestaurants(
                                    state.restaurantResponse.restaurants);
                                return Container(
                                  height: 264 *
                                      state.restaurantResponse.restaurants
                                          .length
                                          .toDouble(),
                                  child: Column(
                                    children: state
                                        .restaurantResponse.restaurants
                                        .map((restaurant) => Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 8.0),
                                              child: RestaurantMainCard(
                                                restaurant: restaurant,
                                                size: 'big',
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      );
                    },
                  ),

                  // ── Normal home content ──────────────────────────────────
                  // Completely independent of FilterCubit internals.
                  // BlocSelector only rebuilds this section when the filter
                  // mode toggles (active ↔ inactive), not on every filter update.
                  BlocSelector<FilterCubit, FilterState, bool>(
                    selector: (state) => state is FilterCategory,
                    builder: (context, isFiltered) {
                      if (isFiltered) return const SizedBox.shrink();
                      return Column(
                        children: [
                          NearbySection(
                            restaurants: nearbyRestaurants,
                            isLoadingRestaurants: _nearbyLoading,
                          ),
                          VisitsHorizontalList(visits: allVisits),
                          BannerAdWidget(),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Listas hechas por expertos',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: "SF Pro Display",
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24.0, vertical: 16),
                            child: Column(
                              children: blogPosts
                                  .map((blogPost) =>
                                      BlogPostComponent(blogPost: blogPost))
                                  .toList(),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
                              child: Text(
                                'Explora las categorías destacas',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: "SF Pro Display",
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            height: 132,
                            child: ListView.builder(
                              shrinkWrap: false,
                              primary: false,
                              itemCount: categories.length,
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      right: 8.0, top: 12),
                                  child: categories[index].foto.isNotEmpty
                                      ? GestureDetector(
                                          onTap: () => GlobalMethods().pushPage(
                                              context,
                                              AdvancedSearch(
                                                categories: categories,
                                                municipalities: municipalities,
                                                types: types,
                                                islandId: islandId,
                                                preSelectedCategories: [
                                                  categories[index]
                                                ],
                                              )),
                                          child: CategoryImageCard(
                                              categories[index]))
                                      : const SizedBox.shrink(),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 18.0),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Text(
                                  'Los favoritos de los usuarios',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: "SF Pro Display",
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            height: MediaQuery.of(context).size.height * 0.46,
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: topRestaurants.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      left: 8, right: 8, top: 12),
                                  child:
                                      TopRestaurantCard(topRestaurants[index]),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 18.0),
                            child: BlocBuilder<TopRestaurantCubit,
                                TopRestaurantState>(
                              builder: (context, state) {
                                if (state is! TopRestaurantLoaded) {
                                  return const SizedBox.shrink();
                                }
                                final restaurants = state.restaurants
                                    .map((r) => Restaurant(
                                          id: r.id,
                                          horarios: r.horarios,
                                          enable: true,
                                          googleUrl: '',
                                          municipio: r.municipio,
                                          mainFoto: r.imagen,
                                          nombre: r.nombre,
                                          direccion: r.direccion,
                                          telefono: '',
                                          destacado: '',
                                          fotos: [],
                                          createdAt: '',
                                          updatedAt: '',
                                          negocioMunicipioId: r.municipio,
                                          menus: [],
                                          categoriaRestaurantes: [],
                                          valoraciones: [],
                                          googleHorarios: r.horarios,
                                          open: r.open,
                                          avgRating: r.avg,
                                          area: '',
                                          lat: 0,
                                          lon: 0,
                                          type: '',
                                        ))
                                    .toList();
                                return Column(
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8.0),
                                      child: GestureDetector(
                                        onTap: () => GlobalMethods().pushPage(
                                            context,
                                            RestaurantList(
                                                restaurants: restaurants)),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: const [
                                            Text(
                                              '🏆 Los favoritos',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 300,
                                      child: ListView.builder(
                                        shrinkWrap: false,
                                        primary: false,
                                        itemCount: restaurants.length,
                                        scrollDirection: Axis.horizontal,
                                        itemBuilder: (context, index) =>
                                            Padding(
                                          padding: const EdgeInsets.only(
                                              right: 8.0),
                                          child: RestaurantMainCard(
                                            size: 'small',
                                            restaurant: restaurants[index],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  setAllRestaurants(List<Restaurant> restaurants) {
    setState(() {
      allSurveyRestaurants = restaurants;
    });
  }

  @override
  setSurveyRestaurants(List<Restaurant> restaurants) {
    setState(() {
      allSurveyRestaurants = restaurants;
    });
    presenter.getSurveyResults(restaurants);
  }

  createMenuForRestaurants() {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Container(
        height: 48,
        width: double.infinity,
        child: Center(
          child: ListView.builder(
              shrinkWrap: true,
              primary: false,
              scrollDirection: Axis.horizontal,
              itemCount: menuOptions.length,
              itemBuilder: (context, index) {
                return Wrap(
                  children: [
                    GestureDetector(
                      onTap: () => {
                        menuHandle(index),
                      },
                      child: Container(
                        margin: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            border: Border.all(color: Colors.blue, width: 1),
                            color: menuRestaurantSelected == index
                                ? Colors.blue
                                : Colors.white),
                        height: 32,
                        child: Center(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Text(menuOptions[index],
                                style: TextStyle(
                                    color: menuRestaurantSelected == index
                                        ? Colors.white
                                        : Colors.blue)),
                          ),
                        ),
                      ),
                    )
                  ],
                );
              }),
        ),
      ),
    );
  }

  createOpenListWidget() {
    Widget aux = BlocBuilder<RestaurantCubit, RestaurantState>(
        builder: (context, state) {
      if (state is AllRestaurantLoaded) {
        List<Restaurant> restaurants = [];
        state.restaurantResponse.restaurants.forEach((element) => {
              if (element.open)
                {
                  restaurants.add(element),
                }
            });
        return Container(
          height: 220,
          width: double.infinity,
          child: ListView.builder(
              shrinkWrap: true,
              primary: false,
              itemCount: restaurants.length > 0
                  ? restaurants.length < 6
                      ? restaurants.length + 1
                      : 6
                  : 1,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                if (index == 5 ||
                    (restaurants.length < 6 && index == restaurants.length)) {
                  return Wrap(
                    alignment: WrapAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => GlobalMethods().pushPage(
                            context, RestaurantShowMoreGuachinches('open')),
                        child: Container(
                            height: 145,
                            margin: EdgeInsets.fromLTRB(10, 16, 0, 0),
                            width: MediaQuery.of(context).size.width * 0.8,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              color: Colors.blue,
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.white,
                                  offset: Offset(0.0, 1.0),
                                  blurRadius: 0.8,
                                ),
                              ],
                            ),
                            child: Center(
                                child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Ver más',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600)),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                )
                              ],
                            ))),
                      ),
                      SizedBox(
                        width: 30.0,
                      ),
                    ],
                  );
                }
                return restaurants.length > 0
                    ? RestaurantOpenCard(restaurants[index])
                    : Container(
                        width: MediaQuery.of(context).size.width,
                        child: Center(
                            child: Text(
                                'Vaya! Parece que no hay restaurantes abiertos')));
              }),
        );
      }
      return Container();
    });
    if (mounted) {
      setState(() {
        openRestaurantsWidgets = aux;
      });
    }
  }

  @override
  setTopRestaurants(List<TopRestaurants> restaurants) {
    if (mounted) {
      setState(() {
        topRestaurants = restaurants;
      });
    }
  }

  menuHandle(int index) {
    setState(() {
      this.menuRestaurantSelected = index;
    });
  }

  @override
  changeCharginInitial() {
    if (mounted) {
      setState(() {
        this.widget.isChargingInitalRestaurants =
            !this.widget.isChargingInitalRestaurants;
      });
    }
  }

  @override
  changeScreen(widget) {
    GlobalMethods().pushAndReplacement(context, widget);
  }

  @override
  setUserId(String id) {
    if (mounted) {
      setState(() {
        userId = id;
        userIdSearched = true;
      });
    }
  }

  @override
  setScreens(List<Widget> screens) {
    if (mounted) {
      setState(() {
        this.screens = screens;
      });
    }
  }

  @override
  setCupones(List<CuponesAgrupados> cuponesAgrupadosParam) {
    setState(() {
      cuponesAgrupados = cuponesAgrupadosParam;
    });
  }

  @override
  setAllVideos(List<Video> videos) {
    setState(() {
      this.videos = videos;
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
    _tryLoadNearby();
  }

  @override
  setRestaurantsFiltered(List<Restaurant> restaurantsFiltered1,
      List<Restaurant> restaurantsFiltered2) {
    setState(() {
      restaurantsFilteredGuachinches = restaurantsFiltered1;
      restaurantsFilteredGuachinchesByViews = restaurantsFiltered2;
    });
  }

  @override
  setBlogPosts(List<BlogPost> blogPosts) {
    setState(() {
      this.blogPosts = blogPosts;
    });
  }

  @override
  setNearbyRestaurants(List<NearbyRestaurant> restaurants) {
    setState(() {
      nearbyRestaurants = restaurants;
      _nearbyLoading = false;
    });
  }

  @override
  setIsland(String islandId) {
    setState(() {
      this.islandId = islandId;
    });
    _tryLoadNearby();
    presenter.getRestaurantsFilterByCategory(
        '11a5f3a4-3ce3-48bb-9749-03eac640e23e', islandId);
    presenter.getAllMunicipalities(islandId);
    presenter.getAllRestaurants(islandId);
  }

  @override
  setSurveyResults(List<SurveyResult> guachinchesModernos,
      List<SurveyResult> guachinchesTradicionales) {
    setState(() {
      surveyGuachinchesModernos = guachinchesModernos;
      surveyGuachinchesTradicionales = guachinchesTradicionales;
      surveyRanking = SurveyRanking(
        guachinchesModernos: surveyGuachinchesModernos,
        guachinchesTradicionales: surveyGuachinchesTradicionales,
        allRestaurants: allSurveyRestaurants,
        isInitialTraditional: true,
        onRefresh: () => presenter.getSurveyResults(allSurveyRestaurants),
      );
    });
    _surveyPreviewTimer?.cancel();
    _surveyPreviewTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        setState(() {
          _surveyPreviewIsTraditional = !_surveyPreviewIsTraditional;
        });
      }
    });
  }

  @override
  setAllVisits(List<Visit> visits) {
    setState(() {
      allVisits = visits;
    });
  }

  Widget _buildSurveyResultsPreview() {
    final currentData = _surveyPreviewIsTraditional
        ? surveyGuachinchesTradicionales.take(3).toList()
        : surveyGuachinchesModernos.take(3).toList();
    final title = _surveyPreviewIsTraditional
        ? 'Guachinches Tradicionales'
        : 'Guachinches Modernos';

    return GestureDetector(
      onTap: () => GlobalMethods().pushPage(context, surveyRanking!),
      child: Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/encuesta_tradicional.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.45)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _surveyTab('Tradicionales', _surveyPreviewIsTraditional,
                        () => setState(() => _surveyPreviewIsTraditional = true)),
                    const SizedBox(width: 8),
                    _surveyTab('Modernos', !_surveyPreviewIsTraditional,
                        () => setState(() => _surveyPreviewIsTraditional = false)),
                  ],
                ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Align(
                      key: ValueKey(title),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.12),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: Column(
                      key: ValueKey(_surveyPreviewIsTraditional),
                      children: currentData.asMap().entries.map((e) {
                        return RankingCard(
                          position: e.key + 1,
                          name: e.value.restaurant?.nombre ?? '',
                          votes: e.value.votes.toString(),
                          height: e.key == 0 ? 72 : 58,
                          isWinner: e.key == 0,
                          votedByUser: e.value.isVotedByUser,
                          logoUrl: e.value.restaurant?.mainFoto ?? '',
                        );
                      }).toList(),
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

  Widget _surveyTab(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color.fromRGBO(51, 189, 236, 1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, color: Colors.white, size: 14),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontFamily: 'SF Pro Display',
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final Shader linearGradient = LinearGradient(
  colors: <Color>[Color(0xff0189C4), Color(0xff01BCC4)],
).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0));

// Pantalla de búsqueda
class SearchPage22 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Buscar"),
      ),
      body: Center(
        child: Text("Pantalla de búsqueda"),
      ),
    );
  }
}
