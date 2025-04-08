import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/data/model/Cupones.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/user_info.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/favoritos/favoritos.dart';
import 'package:guachinches/ui/pages/mis_visitas/mis_visitas.dart';
import 'package:guachinches/ui/pages/profile/pin.dart';
import 'package:guachinches/ui/pages/profile/profile_presenter.dart';
import 'package:guachinches/ui/pages/splash_screen/splash_screen.dart';
import 'package:guachinches/ui/pages/valoraciones/valoraciones.dart';
import 'package:http/http.dart';


class Profilev2 extends StatefulWidget {

  @override
  State<Profilev2> createState() => _Profilev2State();
}

class _Profilev2State extends State<Profilev2> implements ProfileView{
  late RemoteRepository remoteRepository;
  late ProfilePresenter _presenter;

  @override
  void initState() {
    final userCubit = context.read<UserCubit>();
    remoteRepository = HttpRemoteRepository(Client());
    _presenter = ProfilePresenter(this, userCubit, remoteRepository);
  }

  @override
  Widget build(BuildContext context) {
    return  CupertinoPageScaffold(child: CustomScrollView(
      slivers: [
        const CupertinoSliverNavigationBar(
          backgroundColor: Color.fromRGBO(25, 27, 32, 1),
          largeTitle: Text('Mi Perfil', style: TextStyle(color: Colors.white, fontFamily: 'SF Pro Display'),),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal:24.0,vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                  children:[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BlocBuilder<UserCubit, UserState>(
                          builder: (context, state){
                            UserInfo userInfo = UserInfo(); // Asumiendo que UserInfo es una clase definida en tu aplicación

                            if (state is UserLoaded) {
                              userInfo = state.user;
                              if (userInfo.nombre.isNotEmpty) {
                                userInfo.nombre =
                                    userInfo.nombre[0].toUpperCase() + userInfo.nombre.substring(1);
                              }
                            }
                            return Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Color.fromRGBO(0, 133, 196, 1), // Color del borde
                                  width: 2.0, // Ancho del borde
                                ),
                                borderRadius: BorderRadius.circular(16.0), // Radio de las esquinas
                              ),
                              height: 100,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 40,
                                          child: Text(userInfo.nombre.length>0?userInfo.nombre[0]:'',style: TextStyle(
                                            fontFamily: 'SF Pro Display',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 32
                                          ),),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 24.0),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(userInfo.nombre, style: TextStyle(fontSize: 24,fontFamily: 'SF Pro Display'),),
                                              Text(userInfo.apellidos, style: TextStyle(fontSize: 16,fontFamily: 'SF Pro Display'),),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        ),
                      // Text("PINES",  style: TextStyle(fontSize: 16),),
                      // Container(
                      //   child: Padding(
                      //     padding: const EdgeInsets.only(top:8.0),
                      //     child: Row(
                      //       children: [
                      //         Pin(title: "Aventurero/a",asset: "assets/images/pin1.png"), // Icono
                      //         Pin(title: "Solidario/a",asset: "assets/images/pin2.png"), // Icono
                      //       ],
                      //     ),
                      //   ),
                      // ),
                      // SizedBox(
                      //   height: 16,
                      // ),
                      SizedBox(
                        height: 24,
                      ),
                      Text("PERFIL",  style: TextStyle(fontSize: 16 ,fontFamily: 'SF Display Pro'),),
                      SizedBox(
                        height: 8,
                      ),
                      // MenuOption(title: "Cupones",asset: "cupones.svg",page: MyCoupons(),),
                      MenuOption(title: "Valoraciones",asset: "valoraciones.svg",page:ValoracionesPage(),),
                      MenuOption(title: "Mis visitas",asset: "rutas.svg",page: MisVisitasPage(),),
                      MenuOption(title: "Favoritos",asset: "fav.svg",page: FavoritosPage(),),
                      SizedBox(height: 16,),
                      // Text("IDENTIFICACIÓN",  style: TextStyle(fontSize: 16),),
                      // SizedBox(
                      //   height: 8,
                      // ),
                      // MenuOption(title: "Código QR",asset: "qr.svg",),
                      // MenuOption(title: "Pasaporte",asset: "pasaporte.svg",),

                    ],
                  ),
                    SizedBox(
                      height: 24,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Column(
                            children: [
                            TextButton(
                              onPressed: ()=>_presenter.logOut(),
                              child: Text('Cerrar sesion',style: TextStyle(
                                fontFamily: 'SF Pro Display',
                                color: Colors.white
                              ),),
                            ),
                              TextButton(
                              onPressed: ()=>_presenter.deleteAccount(),
                              child: Text('Eliminar usuario',style: TextStyle(
                                  fontFamily: 'SF Pro Display',
                                  color: Colors.grey
                              ),),
                            ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ]
            ),
          ),
    )]));
  }


  @override
  setUserInfo(UserInfo userInfo) {
    // TODO: implement setUserInfo
    throw UnimplementedError();
  }
  @override

  goSplashScreen() {
    GlobalMethods().pushAndReplacement(context, SplashScreen());
  }

  @override
  updateCupones(List<Cupones> cupones) {
    // TODO: implement updateCupones
    throw UnimplementedError();
  }

  @override
  updateListSql(List<Restaurant> restaurants) {
    // TODO: implement updateListSql
    throw UnimplementedError();
  }
}

class MenuOption extends StatelessWidget {
  final String title;
  final String asset;
  final Widget? page;

  const MenuOption({
    Key? key,required this.asset,required this.title, this.page
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ()=> GlobalMethods().pushPage(context, page!),
      child: Container(
        height: 48,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              Row(
                children: [
                  Container(
                    alignment: Alignment.center,
                    width: 24,
                    height: 24,
                    child: SvgPicture.asset(
                      "assets/images/"+asset,  // Reemplaza 'assets/icono.svg' con la ubicación de tu archivo SVG
                      // Alto del icono
                      color: Colors.white,  // Color del icono
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(this.title,style: TextStyle(fontSize: 16, fontFamily: 'SF Pro Display',),),
                  ),
                ],
              ), // Icono
              Icon(Icons.arrow_forward_ios_rounded,size: 16, color: Colors.white,)
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 32.0),
              child: Divider(color:Colors.white30),
            ),
          ],
        ),
      ),
    );
  }
}

class Pin extends StatelessWidget {
  final String title; // Declarar la variable wod como un parámetro
  final String asset; // Declarar la variable wod como un parámetro

  const Pin({Key? key, required this.title,required this.asset}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print("Pin");
        GlobalMethods().pushPageWithFocus(context, PinDetail(title: title,asset: asset,
          description: "Haz visitado algún restaurante dificil de llegar de esos que tienes que preguntar 20 veces antes de encontrarlo",));
      },
      child: Container(
        child: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Column(
            children: [
              Image.asset(
                asset,
                width: 64,          // Ancho del icono
                height: 64, // Alto del icono
              ),
              Text(title,style: TextStyle(fontSize: 12),)
            ],
          ),
        ),
      ),
    );
  }
}
