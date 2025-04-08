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
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
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
import 'package:guachinches/data/model/blog_post.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/components/SurveyResults/SurveyResults.dart';
import 'package:guachinches/ui/components/app_Bars/appbar_basic.dart';
import 'package:guachinches/ui/components/blog_post/blog_post_component.dart';
import 'package:guachinches/ui/components/cards/restaurantMainCard.dart';
import 'package:guachinches/ui/components/cards/surveyCard.dart';
import 'package:guachinches/ui/components/cards/topRestaurantCard.dart';
import 'package:guachinches/ui/components/cards/restaurantOpenCard.dart';
import 'package:guachinches/ui/components/categories/CategoryImageCard.dart';
import 'package:guachinches/ui/components/heroSliderComponent.dart';
import 'package:guachinches/ui/components/rankingList.dart';
import 'package:guachinches/ui/pages/advance_search/advanced_search.dart';
import 'package:guachinches/ui/pages/changeIsland/change_island.dart';
import 'package:guachinches/ui/pages/home/home_presenter.dart';
import 'package:guachinches/ui/pages/restaurantList/restaurant_list.dart';
import 'package:guachinches/ui/pages/restaurantsShowMore/restaurantsShowMoreGuachinches.dart';
import 'package:guachinches/ui/pages/surveyRanking/surveyRanking.dart';
import 'package:http/http.dart';

class Home extends StatefulWidget {
  bool isChargingInitalRestaurants = true;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> implements HomeView {
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

  List<BlogPost> blogPosts = [];
  Color _appBarBackgroundColor = Colors.transparent;

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
    presenter.getAllBlogPosts();
    presenter.getTopRestaurants();
    presenter.getSurveyRestaurants();
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

  Color bgColor = Color.fromRGBO(25, 27, 32, 1);

  // Escucha el desplazamiento del scroll para cambiar el fondo de la app bar

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                          if (surveyRanking !=null) {
                            return HeroSliderComponent(
                                state.banners, surveyRanking: surveyRanking,);
                          }
                          return HeroSliderComponent(
                              state.banners);
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
                  BlocBuilder<FilterCubit, FilterState>(
                      builder: (context, state) {
                    if (state is FilterCategory) {
                      return Container(
                        color: Color.fromRGBO(25, 27, 32, 1),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14.0),
                              child:
                                  BlocBuilder<RestaurantCubit, RestaurantState>(
                                      builder: (context, state) {
                                final ScrollController _scrollController =
                                    new ScrollController();
                                if (state is RestaurantFilter) {
                                  return Container(
                                    height: 280 *
                                        state.filtersRestaurants.length
                                            .toDouble(),
                                    // Assuming 264 is the height of each item
                                    child: Column(
                                      children: state.filtersRestaurants
                                          .map((restaurant) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 8.0),
                                          child: RestaurantMainCard(
                                            restaurant: restaurant,
                                            size: 'big',
                                          ),
                                        );
                                      }).toList(),
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
                                          .map((restaurant) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 8.0),
                                          child: RestaurantMainCard(
                                            restaurant: restaurant,
                                            size: 'big',
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  );
                                }
                                return Container();
                              }),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Container(
                              child: Row(
                                mainAxisAlignment:MainAxisAlignment.spaceBetween,
                                children: [
                                  Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('Resultados votaciones',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontFamily: "SF Pro Display"))),
                                  surveyGuachinchesTradicionales.isNotEmpty &&
                                      surveyGuachinchesModernos.isNotEmpty?ElevatedButton(
                                    onPressed: () => {
                                        GlobalMethods().pushPage(
                                            context, SurveyRanking(
                                          guachinchesModernos:
                                          surveyGuachinchesModernos,
                                          guachinchesTradicionales:
                                          surveyGuachinchesTradicionales,
                                          allRestaurants: allSurveyRestaurants,
                                          isInitialTraditional: true,
                                          onRefresh:  ()=>presenter.getSurveyResults(allSurveyRestaurants),
                                        ))
                                    },
                                    style: ButtonStyle(
                                        shape: MaterialStateProperty.all(RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8), // <-- Radius
                                        ),),
                                        backgroundColor: MaterialStateProperty.all(GlobalMethods.blueColor
                                        )
                        ),
                                    child:Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        "Votar",
                                        style: TextStyle(
                                            fontFamily: "SF Pro Display",
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 16.0),
                                      ),
                                    ),
                                  ):Container(),
                                ],
                              ),
                            ),
                          ),
                          surveyGuachinchesTradicionales.isNotEmpty &&
                                  surveyGuachinchesModernos.isNotEmpty
                              ? RankingList(
                                  guachinchesModernos:
                                      surveyGuachinchesModernos,
                                  guachinchesTradicionales:
                                      surveyGuachinchesTradicionales,
                            allRestaurants: allSurveyRestaurants,
                            onRefresh:  ()=>presenter.getSurveyResults(allSurveyRestaurants),

                          )
                              : Container(),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Listas hechas por expertos',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontFamily: "SF Pro Display"))),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24.0, vertical: 16),
                            child: Column(
                              children: blogPosts.map((blogPost) {
                                return BlogPostComponent(blogPost: blogPost);
                              }).toList(),
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
                                  padding: EdgeInsets.only(
                                    right: 8.0,
                                    top: 12,
                                  ),
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
                                      : Container(),
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
                                    padding: EdgeInsets.only(
                                      left: 8,
                                      right: 8,
                                      top: 12,
                                    ),
                                    child: TopRestaurantCard(
                                        topRestaurants[index]));
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 18.0),
                            child: BlocBuilder<TopRestaurantCubit,
                                TopRestaurantState>(builder: (context, state) {
                              final ScrollController _scrollController =
                                  new ScrollController();
                              if (state is TopRestaurantLoaded) {
                                List<Restaurant> restaurants = [];
                                for (int i = 0;
                                    i < state.restaurants.length;
                                    i++) {
                                  restaurants.add(new Restaurant(
                                      id: state.restaurants[i].id,
                                      horarios: state.restaurants[i].horarios,
                                      enable: true,
                                      googleUrl: '',
                                      municipio: state.restaurants[i].municipio,
                                      mainFoto: state.restaurants[i].imagen,
                                      nombre: state.restaurants[i].nombre,
                                      direccion: state.restaurants[i].direccion,
                                      telefono: '',
                                      destacado: '',
                                      fotos: [],
                                      createdAt: '',
                                      updatedAt: '',
                                      negocioMunicipioId:
                                          state.restaurants[i].municipio,
                                      menus: [],
                                      categoriaRestaurantes: [],
                                      valoraciones: [],
                                      googleHorarios:
                                          state.restaurants[i].horarios,
                                      open: state.restaurants[i].open,
                                      avgRating: state.restaurants[i].avg,
                                      area: '',
                                      lat: 0,
                                      lon: 0,
                                      type: ''));
                                }
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
                                          children: [
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
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 300,
                                      child: ListView.builder(
                                          shrinkWrap: false,
                                          primary: false,
                                          controller: _scrollController,
                                          // default is 40
                                          itemCount: state.restaurants.length,
                                          scrollDirection: Axis.horizontal,
                                          itemBuilder: (context, index) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8.0),
                                              child: RestaurantMainCard(
                                                  size: 'small',
                                                  restaurant:
                                                      restaurants[index]),
                                            );
                                          }),
                                    ),
                                  ],
                                );
                              }
                              return Container();
                            }),
                          ),
                        ],
                      );
                    }
                  }),
                ],
              ),
            ),
          ),
        ],
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
  setIsland(String islandId) {
    setState(() {
      this.islandId = islandId;
    });
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
        guachinchesModernos:
        surveyGuachinchesModernos,
        guachinchesTradicionales:
        surveyGuachinchesTradicionales,
        allRestaurants: allSurveyRestaurants,
        isInitialTraditional: true,
        onRefresh:  ()=>presenter.getSurveyResults(allSurveyRestaurants),

      );
    });
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
