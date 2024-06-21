import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
import 'package:guachinches/ui/components/app_Bars/appbar_basic.dart';
import 'package:guachinches/ui/components/blog_post/blog_post_component.dart';
import 'package:guachinches/ui/components/cards/restaurantMainCard.dart';
import 'package:guachinches/ui/components/cards/topRestaurantCard.dart';
import 'package:guachinches/ui/components/cards/restaurantOpenCard.dart';
import 'package:guachinches/ui/components/filters/filterBar.dart';
import 'package:guachinches/ui/components/heroSliderComponent.dart';
import 'package:guachinches/ui/pages/BlogPostDetail/blogPostDetail.dart';
import 'package:guachinches/ui/pages/home/home_presenter.dart';
import 'package:guachinches/ui/pages/restaurantList/restaurant_list.dart';
import 'package:guachinches/ui/pages/restaurantsShowMore/restaurantsShowMore.dart';
import 'package:guachinches/ui/pages/restaurantsShowMore/restaurantsShowMoreGuachinches.dart';
import 'package:http/http.dart';

class Home extends StatefulWidget {
  List<TopRestaurants> restaurants = [];
  bool isChargingInitalRestaurants = true;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> implements HomeView {
  late AppBarBasic appBarBasic;
  List<String> selectedCategories = [];
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
  late String userId;
  List<String> assets = [
    "assets/images/firstTop.png",
    "assets/images/secondTop.png",
    "assets/images/thirdTop.png",
    "assets/images/otherTop.png",
    "assets/images/otherTop.png"
  ];
  List<CuponesAgrupados> cuponesAgrupados = [];
  bool userIdSearched = false;
  final ScrollController _scrollController = new ScrollController();
  bool showCategoryChip = false;
  late FilterCubit filterCubit;
  late RestaurantCubit restaurantsCubit;

  List<BlogPost> blogPosts = [];

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

    presenter.getAllVideos();
    presenter
        .getRestaurantsFilterByCategory('11a5f3a4-3ce3-48bb-9749-03eac640e23e');
    presenter.getAllCategories();
    presenter.getAllTypes();
    presenter.getAllMunicipalities('76ac0bec-4bc1-41a5-bc60-e528e0c12f4d');
    presenter.getAllBlogPosts();

    _scrollController.addListener(_onScroll);
    if (bannersCubit.state is BannersInitial) {
      presenter.getAllBanner();
    }
    if (restaurantsCubit.state is RestaurantInitial ||
        restaurantsCubit.state is RestaurantLoaded) {
      presenter.getAllRestaurants();
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

  @override
  Widget build(BuildContext context) {
    bool showFiltered = false;
    bool _pinned = true;
    bool _snap = false;
    bool _floating = false;

    return Scaffold(
      backgroundColor: Color.fromRGBO(25, 27, 32, 1),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: _pinned,
            elevation: 0,
            backgroundColor: Color.fromRGBO(25, 27, 32, 1),
            snap: _snap,
            floating: _floating,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: EdgeInsets.only(left: 24, bottom: 16),
              // Establecer todos los lados a 0
              title: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: 20,
                  ),
                  Text(
                    'Tenerife',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
          SliverAppBar(
            pinned: false,
            backgroundColor: Color.fromRGBO(25, 27, 32, 1),
            elevation: 0,
            toolbarHeight: -6,
            collapsedHeight: -6,
            expandedHeight: -6,
            flexibleSpace: FlexibleSpaceBar(
              title: Container(
                height: 52.0,
                margin: EdgeInsets.only(left: 24.0),
                child: BlocBuilder<FilterCubit, FilterState>(
                    builder: (context, state) {
                  if (state is FilterCategory) {
                    selectedCategories = state.categorySelected;
                    selectedMunicipalities = state.municipalitesSelected;
                    typesSelected = state.typesSelected;
                  } else if (state is FilterInitial) {
                    selectedCategories = [];
                    selectedMunicipalities = [];
                    typesSelected = [];
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    primary: false,
                    itemCount: categories.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      bool isCheck =
                          selectedCategories.contains(categories[index].id);
                      return GestureDetector(
                        onTap: () => {
                          setState(() {
                            List<String> selectedCategoriesAux =
                                selectedCategories;
                            if (isCheck) {
                              selectedCategoriesAux
                                  .remove(categories[index].id);
                            } else {
                              selectedCategories.add(categories[index].id);
                            }
                            filterCubit.handleFilterChange(
                                selectedCategories, [], typesSelected, '');
                            this.selectedCategories = selectedCategoriesAux;
                          }),
                          restaurantsCubit.getFilterRestaurants(
                            categories: selectedCategories,
                            municipalities: selectedMunicipalities,
                            text: '',
                            types: [],
                            islandId: '76ac0bec-4bc1-41a5-bc60-e528e0c12f4d',
                            isOpen: false,
                          ),
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isCheck ? Colors.white : bgColor,
                              border: Border.all(
                                color: Colors.white, // Border color
                                width: 1.0, // Border width
                              ),
                              borderRadius: BorderRadius.circular(
                                  18.0), // Rounded corners
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                              child: Row(
                                children: [
                                  SvgPicture.network(
                                    categories[index].iconUrl,
                                    width: 16.0,
                                    height: 16.0,
                                  ),
                                  SizedBox(
                                    height: 8,
                                    width: 8,
                                  ),
                                  Center(
                                    child: Text(
                                      categories[index].nombre,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isCheck ? bgColor : Colors.white,
                                        fontWeight: isCheck
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ),
          BlocBuilder<FilterCubit, FilterState>(builder: (context, state) {
            bool isFiltering = false;
            if (state is FilterCategory) {
              isFiltering = true;
            }
            return SliverAppBar(
              pinned: true,
              floating: false,
              bottom: PreferredSize(
                // Add this code
                preferredSize: isFiltering
                    ? Size.fromHeight(-24.0)
                    : Size.fromHeight(-72.0), // Add this code
                child: Text(''), // Add this code
              ),
              primary: true,
              backgroundColor: bgColor,
              elevation: 0,
              collapsedHeight: 60,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsets.only(left: 24, bottom: 16),
                // Establecer todos los lados a 0
                title: Container(
                  child: Column(
                    children: [
                      Container(
                        height: 30,
                        child: FilterBar(
                          showCategoryChip: showCategoryChip,
                          categories: categories,
                          filterMap: false,
                          municipalities: municipalities,
                          types: types,
                        ),
                      ),
                      isFiltering
                          ? BlocBuilder<RestaurantCubit, RestaurantState>(
                              builder: (context, state) {
                              int totalRestaurant = 0;
                              if (state is RestaurantFilter) {
                                totalRestaurant =
                                    state.filtersRestaurants.length;
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      totalRestaurant.toString(),
                                      style: TextStyle(
                                          color: Color.fromRGBO(23, 23, 23, 1),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    Chip(
                                        label: GestureDetector(
                                          onTap: () {
                                            filterCubit.handleFilterChange(
                                                [], [], [], '');
                                          },
                                          child: Text(
                                            'Restablecer',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  Color.fromRGBO(23, 23, 23, 1),
                                            ),
                                          ),
                                        ),
                                        backgroundColor:
                                            Color.fromRGBO(231, 231, 231, 1))
                                  ],
                                );
                              } else {
                                return Container();
                              }
                            })
                          : Container(),
                    ],
                  ),
                ),
              ),
            );
          }),
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
                                  return Container(
                                    height: 264 *
                                        state.restaurantResponse.restaurants
                                            .length
                                            .toDouble(),
                                    // Assuming 264 is the height of each item
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
                          SizedBox(
                            height: 16,
                          ),
                          BlocBuilder<BannersCubit, BannersState>(
                              builder: (context, state) {
                            if (state is BannersLoaded) {
                              return HeroSliderComponent(state.banners);
                            } else {
                              return Container();
                            }
                          }),
                          SizedBox(
                            height: 16,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 24.0),
                            child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text('⭐️ Lista hechas por expertos',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ))),
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
                          Align(
                            alignment: Alignment.topLeft,
                            child: Container(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () => GlobalMethods().pushPage(
                                          context,
                                          RestaurantList(
                                              restaurants:
                                                  restaurantsFilteredGuachinches)),
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                            top: 16, bottom: 16, right: 8),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '🍷 Guachinches tradicionales',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
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
                                          // default is 40
                                          itemCount:
                                              restaurantsFilteredGuachinches
                                                  .length,
                                          scrollDirection: Axis.horizontal,
                                          itemBuilder: (context, index) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8.0),
                                              child: RestaurantMainCard(
                                                  size: 'small',
                                                  restaurant:
                                                      restaurantsFilteredGuachinches[
                                                          index]),
                                            );
                                          }),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topLeft,
                            child: Container(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () => GlobalMethods().pushPage(
                                          context,
                                          RestaurantList(
                                              restaurants:
                                                  restaurantsFilteredGuachinchesByViews)),
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                            top: 16, bottom: 16, right: 8),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '🏞️ Con vistas',
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
                                          // default is 40
                                          itemCount:
                                              restaurantsFilteredGuachinchesByViews
                                                  .length,
                                          scrollDirection: Axis.horizontal,
                                          itemBuilder: (context, index) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8.0),
                                              child: RestaurantMainCard(
                                                  size: 'small',
                                                  restaurant:
                                                      restaurantsFilteredGuachinchesByViews[
                                                          index]),
                                            );
                                          }),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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

  createListWidgetForRestaurants() {
    Widget aux = BlocBuilder<TopRestaurantCubit, TopRestaurantState>(
        builder: (context, state) {
      if (state is TopRestaurantLoaded) {
        widget.restaurants = state.restaurants;
        return Container(
          height: 220,
          width: double.infinity,
          child: ListView.builder(
              shrinkWrap: true,
              primary: false,
              itemCount: 6,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                print(index);
                if (index == 5) {
                  return Wrap(
                    alignment: WrapAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => GlobalMethods()
                            .pushPage(context, RestaurantShowMore('top')),
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
                return TopRestaurantCard(widget.restaurants[index]);
              }),
        );
      }
      return Container();
    });
    if (mounted) {
      setState(() {
        restaurantsWidgets = aux;
      });
    }
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
        this.widget.restaurants = restaurants;
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
}

final Shader linearGradient = LinearGradient(
  colors: <Color>[Color(0xff0189C4), Color(0xff01BCC4)],
).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0));
