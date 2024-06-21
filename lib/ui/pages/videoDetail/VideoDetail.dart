import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/cubit/menu/menu_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_state.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/data/model/Video.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/components/cards/TopRestaurantListCard.dart';
import 'package:video_player/video_player.dart';
import 'package:tiktoklikescroller/tiktoklikescroller.dart';

class VideoDetail extends StatefulWidget {
  final List<Video> videos;
  final int initialIndex;

  const VideoDetail({Key? key, required this.videos, this.initialIndex = 0}) : super(key: key);

  @override
  _VideoDetailState createState() => _VideoDetailState();
}

class _VideoDetailState extends State<VideoDetail> {
  late List<String> videoUrls;
  late List<Video> videos;
  int actualIndex = 0;

  @override
  void initState() {
    super.initState();
    videos = widget.videos;
    videoUrls = videos.map((e) => e.urlVideo).toList();
    actualIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final Controller controller = Controller()
      ..addListener((event) {
        _handleCallbackEvent(event.direction, event.success, currentIndex: event.pageNo);
      });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: videoUrls.isNotEmpty
          ? TikTokStyleFullPageScroller(
        contentSize: videoUrls.length,
        swipePositionThreshold: 0.3,
        swipeVelocityThreshold: 1000,
        animationDuration: const Duration(milliseconds: 400),
        controller: controller,
        builder: (BuildContext context, int index) {
          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: VideoPlayerWidget(
                  videoUrl: videoUrls[index],
                  index: index,
                  currentIndex: actualIndex,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.all(22.0),
                  child: BlocBuilder<RestaurantCubit, RestaurantState>(
                    builder: (context, state) {
                      String restaurantId = videos[index].restaurantId;
                      late Restaurant restaurant;
                      if (state is AllRestaurantLoaded) {
                        state.restaurantResponse.restaurants.forEach((element) {
                          if (element.id == restaurantId) {
                            restaurant = element;
                          }
                        });
                        TopRestaurants topRestaurant = TopRestaurants(
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
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: TopRestaurantListCard(topRestaurant),
                          ),
                        );
                      }
                      return Container();
                    },
                  ),
                ),
              ),
            ],
          );
        },
      )
          : Center(child: CircularProgressIndicator()),
    );
  }

  void _handleCallbackEvent(ScrollDirection direction, ScrollSuccess success, {int? currentIndex}) {
    setState(() {
      actualIndex = currentIndex!;
    });
    print("Scroll callback received with data: {direction: $direction, success: $success and index: ${currentIndex ?? 'not given'}}");
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final int index;
  final int currentIndex;

  VideoPlayerWidget({
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
    _videoPlayerController = VideoPlayerController.network(widget.videoUrl);
    _initializeVideoPlayerFuture = _videoPlayerController.initialize();
    _videoPlayerController.setLooping(true);
    if (widget.index == widget.currentIndex) {
      _videoPlayerController.play();
    }
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index == widget.currentIndex && !_videoPlayerController.value.isPlaying) {
      _videoPlayerController.play();
    } else if (widget.index != widget.currentIndex && _videoPlayerController.value.isPlaying) {
      _videoPlayerController.pause();
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuCubit, MenuState>(builder: (context, menuState) {
      return FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return AspectRatio(
              aspectRatio: _videoPlayerController.value.aspectRatio,
              child: GestureDetector(
                onTap: () {
                  if (widget.index == widget.currentIndex) {
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
    });
  }
}
