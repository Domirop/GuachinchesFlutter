import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/menu/menu_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_state.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/data/model/Video.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/components/cards/TopRestaurantListCard.dart';
import 'package:guachinches/ui/pages/video/video_presenter.dart';
import 'package:http/http.dart';
import 'package:video_player/video_player.dart';
import 'package:tiktoklikescroller/tiktoklikescroller.dart';

class VideoScreen extends StatefulWidget {
  final int index;

  const VideoScreen({Key? key, required this.index}) : super(key: key);

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen>
    with WidgetsBindingObserver
    implements VideoPresenterView {
  late VideoPresenter presenter;
  late RemoteRepository remoteRepository;
  List<String> videoUrls = [];
  List<Video> videos = [];
  Map<String, Restaurant> restaurantCache = {}; // Cache de restaurantes
  int actualIndex = 0; // Cambiar de -1 a 0 para reproducir el primer video

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    remoteRepository = HttpRemoteRepository(Client());
    presenter = VideoPresenter(this, remoteRepository);
    presenter.getAllVideos();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _pauseAllVideos();
    } else if (state == AppLifecycleState.resumed) {
      if (context.read<MenuCubit>().state.selectedIndex == 2) {
        setState(() {
          actualIndex = actualIndex == -1 && videoUrls.isNotEmpty ? 0 : actualIndex;
        });
        _resumeVideoIfInView();
      }
    }

  }

  void _pauseAllVideos() {
    setState(() {
      actualIndex = -1; // Pausa todos los videos
    });
  }

  void _resumeVideoIfInView() {
    setState(() {
      if (actualIndex != -1) {
        actualIndex = actualIndex; // Mantiene el índice actual activo
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Controller controller = Controller()
      ..addListener((event) {
        _handleCallbackEvent(event.direction, event.success,
            currentIndex: event.pageNo!);
      });

    return MaterialApp(
      home: Scaffold(
        body: videoUrls.isNotEmpty
            ? BlocBuilder<MenuCubit, MenuState>(builder: (context, menuState) {
          TopRestaurants? topRestaurant;
          print("CURRENT INDEX");
          print(actualIndex);
          if (actualIndex >= 0 &&
              actualIndex < videos.length &&
              restaurantCache.containsKey(videos[actualIndex].restaurant.id)) {
            final restaurant = restaurantCache[videos[actualIndex].restaurant.id]!;
            topRestaurant = TopRestaurants(
              nombre: restaurant.nombre,
              open: restaurant.open,
              id: restaurant.id,
              horarios: restaurant.horarios,
              direccion: restaurant.direccion,
              counter: restaurant.avgRating.toString(),
              imagen: restaurant.mainFoto,
              cerrado: restaurant.open.toString(),
              municipio: restaurant.municipio,
              avg: restaurant.avgRating,
            );
          }


          return TikTokStyleFullPageScroller(
            contentSize: videoUrls.length,
            swipePositionThreshold: 0.3,
            swipeVelocityThreshold: 1000,
            animationDuration: const Duration(milliseconds: 400),
            controller: controller,
            builder: (BuildContext context, int index) {
              if (!restaurantCache.containsKey(videos[index].restaurant.id)) {
                presenter.getRestaurantDetails(videos[index].restaurant.id);
              }

              return Stack(
                children: [
                  Positioned.fill(
                    child: VideoPlayerWidget(
                      videoUrl: videoUrls[index],
                      index: index,
                      currentIndex: actualIndex,
                    ),
                  ),
                  if (topRestaurant != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TopRestaurantListCard(topRestaurant),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        })
            : Container(),
      ),
    );
  }

  void _handleCallbackEvent(ScrollDirection direction, ScrollSuccess success,
      {int? currentIndex}) {
    setState(() {
      actualIndex = currentIndex ?? 0; // Maneja el primer índice de manera predeterminada
    });
    print(
        "Scroll callback received with data: {direction: $direction, success: $success and index: ${currentIndex ?? 'not given'}}");
  }

  @override
  setVideos(List<Video> videos) {
    setState(() {
      videoUrls = videos.map((e) => e.urlVideo).toList();
      this.videos = videos;
    });
  }

  @override
  setRestaurant(Restaurant restaurant) {
    setState(() {
      restaurantCache[restaurant.id] = restaurant;
    });
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final int index;
  final int currentIndex;

  const VideoPlayerWidget({
    required this.videoUrl,
    required this.index,
    required this.currentIndex,
  });

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _initializeVideoController();
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl ||
        oldWidget.currentIndex != widget.currentIndex) {
      _disposeController();
      _initializeVideoController();
    } else {
      if (widget.index != widget.currentIndex) {
        _videoPlayerController.pause();
      }
    }
  }

  void _initializeVideoController() {
    _videoPlayerController = VideoPlayerController.network(widget.videoUrl);
    _initializeVideoPlayerFuture = _videoPlayerController.initialize();
    _videoPlayerController.setLooping(true);

    if (widget.index == widget.currentIndex) {
      _videoPlayerController.play();
    }
  }

  void _disposeController() {
    _videoPlayerController.pause();
    _videoPlayerController.dispose();
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuCubit, MenuState>(
      builder: (context, menuState) {
        if (widget.index == widget.currentIndex && menuState.selectedIndex == 2) {
          if (!_videoPlayerController.value.isPlaying) {
            _videoPlayerController.play();
          }
        } else {
          _videoPlayerController.pause();
        }

        return FutureBuilder(
          future: _initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return AspectRatio(
                aspectRatio: _videoPlayerController.value.aspectRatio,
                child: GestureDetector(
                  onTap: () {
                    if (widget.index == widget.currentIndex &&
                        menuState.selectedIndex == 2) {
                      if (_videoPlayerController.value.isPlaying) {
                        _videoPlayerController.pause();
                      } else {
                        _videoPlayerController.play();
                      }
                    }
                  },
                  child: VideoPlayer(_videoPlayerController),
                ),
              );
            } else {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        );
      },
    );
  }
}
