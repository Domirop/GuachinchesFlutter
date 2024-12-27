import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/svg.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/data/model/Video.dart';
import 'package:guachinches/data/model/fotos.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/Others/new_review/new_review.dart';
import 'package:guachinches/ui/components/details_image_slider/detail_slider.dart';
import 'package:guachinches/ui/pages/details/details_presenter.dart';
import 'package:guachinches/ui/pages/login/login.dart';
import 'package:guachinches/ui/pages/videoDetail/VideoDetail.dart';
import 'package:guachinches/ui/pages/videoInput/videoInput.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_compress/video_compress.dart';
import 'package:image/image.dart' as img;

class Details extends StatefulWidget {
  final String id;

  Details(this.id);

  @override
  _DetailsState createState() => _DetailsState();
}

class _DetailsState extends State<Details> implements DetailView {
   String userId = '';
  String id = '';
  bool isFav = false;
  late Restaurant restaurant;
  int indexCarta = 0;
  int indexValoraciones = 0;
  int indexSection = 0;
  late DetailPresenter presenter;
  late RemoteRepository remoteRepository;
  final cardKey = GlobalKey();
  final detailsKey = GlobalKey();
  final reviewsKey = GlobalKey();
  late Fotos mainFoto;
  bool isChargin = true;
  static const kExpandedHeight = 400.0;
  List<Video> videos = [];

  @override
  void initState() {

    super.initState();
    remoteRepository = HttpRemoteRepository(Client());
    id = widget.id;

    _scrollController = ScrollController()
      ..addListener(() {
        setState(() {
          _textColor = _isSliverAppBarExpanded ? Colors.white : Colors.black;
        });
      });
    presenter = DetailPresenter(remoteRepository, this);
    presenter.getRestaurantById(widget.id);
    presenter.getRestaurantVideos(widget.id);
  }
  bool get _isSliverAppBarExpanded {
    return _scrollController.hasClients &&
        _scrollController.offset > kExpandedHeight - 100;

  }
  late ScrollController _scrollController;
  Color _textColor = Colors.white;
  List<MediaInfo> uploadVideos = [];

  Future<void> _pickAndCompressVideo(String title) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);

    if (pickedFile != null) {
      MediaInfo mediaInfo = await VideoCompress.compressVideo(
        pickedFile.path,
        quality: VideoQuality.HighestQuality,
        deleteOrigin: false,

      ) as MediaInfo;
      ;
      final thumbnailFile = await VideoCompress.getByteThumbnail(
          pickedFile.path,
          quality: 50, // default(100)
          position: -1 // default(-1)
      );
      img.Image? image = img.decodeImage(thumbnailFile!);
      if (image != null) {
        List<int> jpgBytes = img.encodeJpg(image, quality: 80);
        // Convert to base64
        String base64String = base64Encode(jpgBytes);
      }
_showBottomSheet(context);
      // presenter.uploadVideo(mediaInfo, title,restaurant.id);

      setState(() {
        uploadVideos.add(mediaInfo);
      });

    }
  }
  void _addVideo(MediaInfo video) {
    presenter.getRestaurantVideos(id);
  }
   static Color bgColor = Color.fromRGBO(25, 27, 32, 1);
   static Color blueColor = Color.fromRGBO(0, 133, 196, 1);


  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    // Calculamos los tamaños de los botones de manera proporcional
    double outlinedButtonWidth = screenWidth * 0.4; // 40% del ancho de la pantalla
    double outlinedButtonHeight = outlinedButtonWidth * 0.32; // Relación de aspecto mantenida
    double elevatedButtonWidth = screenWidth * 0.5; // 50% del ancho de la pantalla
    double elevatedButtonHeight = elevatedButtonWidth * 0.25; // Relación de aspecto mantenida
    // Función para compartir contenido
    void _shareContent() {
      Share.share('Mira este restaurante: ${restaurant.nombre} en ${restaurant.direccion}');

    }

    return Scaffold(
      backgroundColor: bgColor,
      bottomNavigationBar: BottomAppBar(
        color: bgColor,
        child: Padding(
          padding: const EdgeInsets.only(top:12.0),
          child: Row(
            children: [
              SizedBox(width: 16,),
              Container(
                width: outlinedButtonWidth,
                height: outlinedButtonHeight,
                  child: OutlinedButton(
                    style: ButtonStyle(
                      minimumSize: MaterialStateProperty.all(Size(outlinedButtonWidth, outlinedButtonHeight)),
                      elevation: MaterialStateProperty.all(0.0),
                      side: MaterialStateProperty.all(BorderSide(color: blueColor)), // Borde blanco
                    ),

                  onPressed: () {
                    _shareContent();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.ios_share, color: blueColor, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Compartir',
                        style: TextStyle(color: blueColor,fontFamily: 'SF Pro Display'),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 16),
              Container(
                width: elevatedButtonWidth,
                height: elevatedButtonHeight,
                child: ElevatedButton(
                  style: ButtonStyle(
                    minimumSize: MaterialStateProperty.all(Size(elevatedButtonWidth, elevatedButtonHeight)),
                    backgroundColor: MaterialStateProperty.all(blueColor),
                    elevation: MaterialStateProperty.all(0.0),
                  ),
                  onPressed: () {
                    _makePhoneCall(restaurant.telefono); // Reemplaza '123456789' con el número de teléfono deseado
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Llamar por teléfono',

                        style: TextStyle(color: Colors.white,fontFamily: 'SF Pro Display'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: isChargin
          ? Container(
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.center,
              child: CircularProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            )
          : CustomScrollView(
        controller: _scrollController,
        slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: kExpandedHeight-60,
                  elevation: 0.0,
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back_ios,size: 18,color: Colors.white,),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  foregroundColor: Colors.black,
                  floating: true,
                  backgroundColor: bgColor,
                  title: _isSliverAppBarExpanded
                      ? Text(
                    restaurant.nombre!,
                    style: TextStyle(color: Colors.white,fontFamily: 'SF Pro Display'),
                  )
                      : null,
                  flexibleSpace:_isSliverAppBarExpanded?null: Container(
                    width: MediaQuery.of(context).size.width,
                    child: DetailPhotosSlider(
                     restaurant.fotos,
                      restaurant.nombre,
                      restaurant.id
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                      ],
                    ),
                    SizedBox(
                      height: 8.0,
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 10.0, right: 0.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              key: detailsKey,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                //button with border blue and white background
                                Container(
                                  width: double.infinity,
                                  height: 50.0,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        _buildButton('Como llegar', Icons.location_on,()=>{
                                          MapsLauncher.launchQuery('${restaurant.nombre }')
                                        }),
                                        // _buildButton('Llamar', Icons.phone,()=>{
                                        //   _launchCaller(restaurant.telefono)
                                        // }),
                                        // _buildButton('Reservar', Icons.book,()=>{
                                        //   launch("tel:${restaurant.telefono}")
                                        // }),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 8.0,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        restaurant.nombre,
                                        style: TextStyle(
                                          fontSize: 18.0,
                                          fontFamily: 'SF Pro Display',
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 5.0,
                                ),
                                restaurant.avg == "NaN" ||
                                        restaurant.avgRating == null
                                    ? Container(
                                        child: Text(
                                          'Sin Valoraciones',
                                          style: TextStyle(
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    : Row(
                                        children: [
                                          Text(
                                            restaurant.avgRating.toString(),
                                            style: Theme.of(context).textTheme.displayMedium,),
                                          RatingBar.builder(
                                            ignoreGestures: true,
                                            unratedColor: Colors.white30,
                                            initialRating: restaurant.avgRating,
                                            minRating: 1,
                                            direction: Axis.horizontal,
                                            allowHalfRating: true,
                                            itemCount: 5,
                                            itemSize: 30,
                                            glowColor: Colors.white,
                                            onRatingUpdate: (rating) => {},
                                            itemPadding: EdgeInsets.symmetric(
                                                horizontal: 2.0),
                                            itemBuilder: (context, _) => Icon(
                                              Icons.star,
                                              color:
                                                  Color.fromRGBO(0, 133, 196, 1),
                                            ),
                                          ),
                                          Text(
                                            restaurant.valoraciones.length
                                                    .toString() +
                                                ' valoraciones',
                                            style: TextStyle(
                                              fontSize: 10.0,

                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),

                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children:[
                                    Text(
                                    restaurant.horarios == null ? "" : restaurant.horarios!,
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.normal,
                                      fontFamily: 'SF Pro Display',
                                      color: Colors.white,
                                    ),
                                  )]
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    restaurant.direccion.trim(),
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      fontFamily: 'SF Pro Display',
                                      fontWeight: FontWeight.normal,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 12.0,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 15.0,
                    ),
                    // Padding(
                    //   padding: const EdgeInsets.only(left: 12.0),
                    //   child: Text('Recomendado por: '),
                    // ),
                    // Padding(
                    //   padding: const EdgeInsets.all(12.0),
                    //   child: Container(
                    //     decoration: BoxDecoration(
                    //       color: Colors.white,
                    //       borderRadius: BorderRadius.circular(12.0),
                    //       border: Border.all(color:Color.fromRGBO(231, 231, 231, 1)), // Cambia el color según tu preferencia
                    //     ),
                    //     child: Column(
                    //       crossAxisAlignment: CrossAxisAlignment.start,
                    //       children: [
                    //         SizedBox(height: 8.0),
                    //         Container(
                    //           padding: EdgeInsets.all(16.0),
                    //           child: Row(
                    //             children: [
                    //               CircleAvatar(
                    //                 radius: 24.0,
                    //                 backgroundImage: AssetImage('assets/images/logo_gmt.png'),
                    //               ),
                    //               SizedBox(width: 12.0),
                    //               Flexible(
                    //                 child: Column(
                    //                   crossAxisAlignment: CrossAxisAlignment.start,
                    //                   children: [
                    //                     Text(
                    //                       'Guachinches modernos',
                    //                       style: TextStyle(
                    //                         fontWeight: FontWeight.bold,
                    //                       ),
                    //                     ),
                    //                     SizedBox(height: 4.0),
                    //                     Text(
                    //                       '“Comida tradicional y buen vino del país.”',
                    //                       style: TextStyle(
                    //                         fontStyle: FontStyle.italic,
                    //                       ),
                    //                       softWrap: true,
                    //                     ),
                    //                   ],
                    //                 ),
                    //               ),
                    //             ],
                    //           ),
                    //         ),
                    //         Container(
                    //           height: 32.0,
                    //           width: double.infinity,
                    //           decoration: BoxDecoration(
                    //               borderRadius: BorderRadius.only(  bottomLeft: Radius.circular(12.0), bottomRight: Radius.circular(12.0)),
                    //               color:  Color.fromRGBO(231, 231, 231, 1)
                    //           ),
                    //           child: Center(
                    //             child: Text(
                    //               'Ver más',
                    //               style: TextStyle(
                    //                 color: Colors.black45,
                    //               ),
                    //             ),
                    //           ),
                    //         )
                    //       ],
                    //     ),
                    //   ),
                    // ),
                    videos.length>0?Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Videos de nuestros verificadores',
                            style: TextStyle(fontSize: 18.0,fontWeight: FontWeight.bold,fontFamily: 'SF Pro Display',color: Colors.white),
                          ),
                          SizedBox(height: 12.0),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ...List.generate(videos.length, (index) {
                              var video = videos[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: buildThumbnailColumn(
                                  presenter,
                                  context,
                                  video.urlVideo, // Aquí se usa la URL del video
                                  video.nombre ?? 'Video', // Título del video
                                  'Ver video', // Texto del botón
                                  video.thumbnail, // Thumbnail del video
                                  videos,
                                  index,
                                ),
                              );
                            }),
                          ],
                        ))
                        ],
                      ),):Container(),
                    BlocBuilder(
                      bloc: BlocProvider.of<UserCubit>(context),
                      builder: (context, UserState state) {
                        if (state is UserLoaded && (state.user.id == 'b5f2687e-20e3-4949-ab43-4ef9d1b8c26b' || state.user.id == '584bc428-0f77-4406-9a81-486e83ad8526')
                        ) {
                          return  Center(
                            child: ElevatedButton(
                              onPressed: ()=>GlobalMethods().pushPage(context, VideoInputPage(onVideoSelected: _addVideo,restaurantId: restaurant.id,)),
                              child: Text('Subir Video'),
                            ),
                          );
                        } else {
                          return Container();
                        }
                      },

                    ),

                    Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Text('Categorias',style: TextStyle(fontSize: 18.0,fontWeight: FontWeight.bold,fontFamily: 'SF Pro Display',color: Colors.white),),
                    ),
                    SizedBox(
                      height: 8.0,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: Color.fromRGBO(231, 231, 231, 0.5),width: 2),
                      ),
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(horizontal: 10.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 2.0,
                          runSpacing: 2.0,
                          children: restaurant.categoriaRestaurantes.map((categoria) {
                            return Container(
                              padding: EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.network(
                                    categoria.categorias.iconUrl,
                                    width: 24.0,
                                    height: 24.0,
                                  ),
                                  SizedBox(width: 8.0), // Espacio entre el icono y el texto
                                  Text(categoria.categorias.nombre,style: TextStyle(
                                    fontSize: 16.0,
                                    fontFamily: 'SF Pro Display',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white
                                  ),), // Mostrar el nombre de la categoría
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 12.0,
                    ),
                    restaurant.valoraciones.isNotEmpty
                        ? Column(
                            children: [
                              Divider(
                                color: Colors.grey,
                                indent: 10.0,
                                endIndent: 10.0,
                              ),
                            ],
                          )
                        : Container(),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 20.0,
                              ),
                              GestureDetector(
                                onTap: () => {
                                  if (this.indexValoraciones == 0)
                                    {
                                      setState(() {
                                        this.indexValoraciones = -1;
                                      })
                                    }
                                  else
                                    {
                                      setState(() {
                                        this.indexValoraciones = 0;
                                      })
                                    }
                                },
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 12.0),
                                  color: Colors.transparent,
                                  width: double.infinity,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Valoraciones",
                                              key: reviewsKey,
                                              style: TextStyle(
                                                fontFamily: 'SF Pro Display',
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      !userId.isEmpty
                                          ? GestureDetector(
                                        onTap: () => {
                                          GlobalMethods().pushPage(
                                              context,
                                              NewReview(
                                                  restaurant, userId, mainFoto.photoUrl!))
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(7.0),
                                            color: Color.fromRGBO(0, 133, 196, 1),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Icon(
                                                  Icons.add,
                                                  color: Colors.white,
                                                ),
                                                Text(
                                                  "Añadir Valoración",
                                                  style: TextStyle(color: Colors.white,fontFamily: 'SF Pro Display',fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                          : Container(),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                const EdgeInsets.only(left:12,top: 8.0),
                                child: Text(
                                  restaurant.valoraciones.length
                                      .toString() +
                                      '+ Reseñas',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                      color: Colors.white),
                                ),
                              ),
                              Container(
                                height: 148,
                                child: ListView.builder(
                                    shrinkWrap: true,
                                    scrollDirection:
                                    Axis.horizontal,
                                    primary: true,
                                    itemCount: restaurant
                                        .valoraciones.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                              padding: EdgeInsets.only(top: 8.0),
                                              child: Container(
                                                width: 292,
                                                padding: EdgeInsets.all(20.0),
                                                margin:
                                                EdgeInsets.symmetric(horizontal: 10.0),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(8.0),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                      MainAxisAlignment.spaceBetween,
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                      children: [
                                                        Column(
                                                          crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                          mainAxisAlignment:
                                                          MainAxisAlignment.center,
                                                          children: [
                                                            Text(
                                                              restaurant
                                                                  .valoraciones[index].usuario == null
                                                                  ? ''
                                                                  : restaurant
                                                                  .valoraciones[index].usuario!.nombre +' '+restaurant
                                                                  .valoraciones[index].usuario!.apellidos.split(' ')[0] ,
                                                              style: TextStyle(
                                                                color: Colors.black,
                                                                fontFamily: 'SF Pro Display',
                                                                fontSize: 14.0,
                                                              ),
                                                            ),
                                                            Container(
                                                              width: 224,
                                                              child: Text(
                                                                restaurant
                                                                    .valoraciones[index].title == null || restaurant
                                                                    .valoraciones[index].title == ''
                                                                    ? "Valoración"
                                                                    : restaurant
                                                                    .valoraciones[index].title,
                                                                overflow: TextOverflow.ellipsis,
                                                                style: TextStyle(
                                                                  fontFamily: 'SF Pro Display',
                                                                  color: Colors.black,
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 12.0,
                                                                ),
                                                              ),
                                                            ),
                                                            Row(
                                                              children: [
                                                                RatingBar.builder(
                                                                  ignoreGestures: true,
                                                                  unratedColor: Colors.grey[300],
                                                                  initialRating:
                                                                  double.parse(restaurant
                                                                      .valoraciones[index].rating),
                                                                  minRating: 1,
                                                                  direction: Axis.horizontal,
                                                                  allowHalfRating: true,
                                                                  itemCount: 5,
                                                                  itemSize: 12,
                                                                  onRatingUpdate: (rating) =>
                                                                  {},
                                                                  itemPadding:
                                                                  EdgeInsets.only(right: 2),
                                                                  itemBuilder: (context, _) =>
                                                                      Icon(
                                                                        Icons.star,
                                                                        color: Color.fromRGBO(
                                                                            0, 133, 196, 1),
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                        Column(
                                                          crossAxisAlignment:
                                                          CrossAxisAlignment.end,
                                                          mainAxisAlignment:
                                                          MainAxisAlignment.start,
                                                          children: [
                                                            SizedBox(
                                                              height: 5.0,
                                                            ),
                                                            Row(
                                                              children: [
                                                                PopupMenuButton(
                                                                  child: Icon(Icons.more_vert,),
                                                                  onSelected: (value) {
                                                                     showDialog(context: context,
                                                                        builder: (context) =>
                                                                        value == 'block user'?
                                                                        AlertDialog(
                                                                          title: Text('¿Quieres bloquear a '+ restaurant
                                                                              .valoraciones[index].usuario!.nombre+'?'),
                                                                          content: Text('No se te mostrarán los comentarios de este usuario'),
                                                                          actions: [
                                                                            OutlinedButton(
                                                                                onPressed: ()=>GlobalMethods().popPage(context),
                                                                                style: OutlinedButton.styleFrom(
                                                                                  side: BorderSide(width: 1.0, color: Colors.red),
                                                                                ),
                                                                                child: Text("No, cancelar",style: TextStyle(color: Colors.red),)),
                                                                            ElevatedButton(
                                                                                onPressed: ()=>presenter.blockUser(userId,restaurant
                                                                                    .valoraciones[index].usuario!.id), child: Text("Si, bloquear"))
                                                                          ],
                                                                        ):AlertDialog(
                                                                          title: Text('¿Quieres reportar este comentario ?'),
                                                                          content: Text('Nuestro equipo investigará tu denuncia, y no se te mostrará este comentario'),

                                                                          actions: [
                                                                            OutlinedButton(
                                                                                onPressed: ()=>GlobalMethods().popPage(context),
                                                                                style: OutlinedButton.styleFrom(
                                                                                  side: BorderSide(width: 1.0, color: Colors.red),
                                                                                ),
                                                                                child: Text("No, cancelar",style: TextStyle(color: Colors.red),)),
                                                                            ElevatedButton(
                                                                                onPressed: ()=>presenter.reportReview(userId, restaurant
                                                                                    .valoraciones[index].id)
                                                                            , child: Text("Si, reportar"))
                                                                          ],
                                                                        )
                                                                    );
                                                                     },
                                                                  itemBuilder: (BuildContext bc) {
                                                                    return const [
                                                                      PopupMenuItem(
                                                                        child: Text("Bloquear usuario"),
                                                                        value: 'block user',
                                                                      ),
                                                                      PopupMenuItem(
                                                                        child: Text(
                                                                            "Reportar Valoración"),
                                                                        value: 'report review',
                                                                      ),
                                                                    ];
                                                                  },
                                                                )
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(
                                                      height: 12.0,
                                                    ),
                                                    Text(
                                                      restaurant
                                                          .valoraciones[index].review != null ? restaurant
                                                          .valoraciones[index].review : "",
                                                      overflow: TextOverflow.ellipsis,
                                                      maxLines: 2,
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 14.0,
                                                      ),
                                                    ),

                                                  ],
                                                ),
                                              ),
                                            );                                  }),
                              )
                            ],
                          ),
                    SizedBox(
                      height: 42.0,
                    ),
                  ],
                ),
              )

        ],
            ),
    );
  }
  void _launchCaller(String phone) async {
    var url = "tel:"+phone; // Reemplaza con el número de teléfono deseado
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'No se pudo realizar la llamada al $url';
    }
  }

  changeSectionIndex(index) {
    setState(() {
      indexSection = index;
    });
  }

  openPhone(phone) {
    launch("tel://" + phone);
  }

  openMap(String address) {
    MapsLauncher.launchQuery(address);
  }

  saveFav() {
    if (this.userId != null) {
      presenter.saveFavRestaurant(widget.id);
    }
  }

  @override
  goToLogin() {
    GlobalMethods().removePagesAndGoToNewScreen(
        context, Login("Para guardar un restaurante debes iniciar sesión."));
  }

  @override
  setUserId(String id) {
    setState(() {
      this.userId = id;
    });
  }

  @override
  setFav(bool correct) {
    setState(() {
      this.isFav = correct;
    });
  }

  @override
  setRestaurant(Restaurant restaurant) {
    if (mounted) {
      Fotos foto = restaurant.fotos.firstWhere(
        (element) => element.type == "principal",
      );

      setState(() {
        this.mainFoto = foto;
        this.restaurant = restaurant;
        this.isChargin = false;
      });
    }
  }
  Future<void> _showBottomSheet(BuildContext context) async {
    String title = '';
    await showModalBottomSheet(
      context: context,

      builder: (context) {
        final titleController = TextEditingController();
        return Container(
          height: MediaQuery.of(context).size.height * 0.5, // Ajusta la altura aquí
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Título del Video'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  title = titleController.text;
                  Navigator.pop(context);
                  _pickAndCompressVideo(title);
                },
                child: Text('Seleccionar Video'),
              ),
            ],
          ),
        );
      },
    );
  }
  @override
  refreshScreen() {
    GlobalMethods().refreshPage(context, Details(id));
  }

  @override
  setRestaurantVideos(List<Video> videos) {
    setState(() {
      this.videos = videos;
    });
  }

  @override
  updateVideos() {
    presenter.getRestaurantVideos(restaurant.id);
  }
}
//calback as parameter

Widget _buildButton(String text, IconData icon,VoidCallback onPressed) {
  return Container(
    child: OutlinedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        elevation: MaterialStateProperty.all(0.0),
        side: MaterialStateProperty.all(BorderSide(width: 1, color: GlobalMethods.blueColor)), // Borde blanco
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0), // Ajusta el valor para redondear más las esquinas
          ),
        ),
      ),

    child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: GlobalMethods.blueColor,
            size: 18,
          ),
          SizedBox(
            width: 8.0,
          ),
          Text(
            text,
            style: TextStyle(
              color: GlobalMethods.blueColor,
              fontFamily: 'SF Pro Display',
              fontSize: 12.0,
            ),
          ),
        ],
      ),
    ),
  );

}
// Función para realizar una llamada telefónica
Future<void> _makePhoneCall(String phoneNumber) async {
  final Uri launchUri = Uri(
    scheme: 'tel',
    path: phoneNumber,
  );
  if (await canLaunch(launchUri.toString())) {
    await launch(launchUri.toString());
  } else {
    // Maneja el error si no se puede realizar la llamada
    print('No se puede realizar la llamada al $phoneNumber');
  }
}
Widget buildThumbnailColumn(
    DetailPresenter presenter,
    BuildContext context, String imageUrl, String title, String views, String thumbnailUrl, List<Video> videos, int index) {

  // Ordenar los videos para que el actual sea el primero
  List<Video> orderedVideos = List.from(videos);
  if (index < orderedVideos.length) {
    Video currentVideo = orderedVideos.removeAt(index);
    orderedVideos.insert(0, currentVideo);
  }

  return GestureDetector(
    onTap: () => GlobalMethods().pushPage(
      context,
      VideoDetail(
        videos: orderedVideos,
        initialIndex: 0, // El video actual ahora es el primero
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Stack(
            alignment: Alignment.bottomLeft,
            children: [
              Image.network(
                thumbnailUrl,
                width: MediaQuery.of(context).size.width / 2.5,
                height: MediaQuery.of(context).size.width / 1.82,
                fit: BoxFit.cover,
              ),
              Positioned(
                bottom: 8.0,
                left: 8.0,
                child: Row(
                  children: [
                    Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 16.0,
                    ),
                    SizedBox(width: 4.0),
                    Text(
                      views,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.0),
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Row(
            children: [
              Text(
                title.length > 16 ? "${title.substring(0, 16)}..." : title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.white,
                ),
              ),

              IconButton(
                  onPressed: (){
                    showDialog(context: context, builder: (context){
                      return AlertDialog(
                        title: Text("Eliminar video"),
                        content: Text("¿Estás seguro de que deseas eliminar este video?"),
                        actions: [
                          TextButton(onPressed: (){
                            Navigator.pop(context);
                          }, child: Text("Cancelar")),
                          TextButton(onPressed: (){
                            Navigator.pop(context);
                            // Eliminar el video
                            presenter.deleteVideo(videos[index].id);
                          }, child: Text("Eliminar")),
                        ],
                      );
                    });
                  },
                  icon: Icon(Icons.delete,color: Colors.red))
            ],
          ),
        ),
      ],
    ),
  );
}
