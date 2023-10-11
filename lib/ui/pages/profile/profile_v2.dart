import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/profile/my_coupons.dart';
import 'package:guachinches/ui/pages/profile/pin.dart';

class Profilev2 extends StatefulWidget {

  @override
  State<Profilev2> createState() => _Profilev2State();
}

class _Profilev2State extends State<Profilev2> {
  @override
  Widget build(BuildContext context) {
    return  CupertinoPageScaffold(child: CustomScrollView(
      slivers: [
        const CupertinoSliverNavigationBar(
          largeTitle: Text('Mi Perfil'),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal:24.0,vertical: 16),
            child: Column(
                  children:[
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Color.fromRGBO(0, 133, 196, 1), // Color del borde
                          width: 2.0, // Ancho del borde
                        ),
                        borderRadius: BorderRadius.circular(16.0), // Radio de las esquinas
                      ),
                      height: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 40,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("@Canarygo", style: TextStyle(fontSize: 24),),
                                    Text("Apellidos", style: TextStyle(fontSize: 16),),
                                  ],
                                ),
                              ),

                            ],
                          ),
                          Text("Editar", style: TextStyle(fontSize: 16),),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 18,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("PINES",  style: TextStyle(fontSize: 16),),
                        Container(
                          child: Padding(
                            padding: const EdgeInsets.only(top:8.0),
                            child: Row(
                              children: [
                                Pin(title: "Aventurero/a",asset: "assets/images/pin1.png"), // Icono
                                Pin(title: "Solidario/a",asset: "assets/images/pin2.png"), // Icono
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 18,
                        ),
                        Text("PERFIL",  style: TextStyle(fontSize: 16),),
                        SizedBox(
                          height: 8,
                        ),
                        MenuOption(title: "Cupones",asset: "cupones.svg",page: MyCoupons(),),
                        MenuOption(title: "Compras",asset: "compras.svg",),
                        MenuOption(title: "Valoraciones",asset: "fav.svg",),
                        MenuOption(title: "Rutas",asset: "rutas.svg",),
                        MenuOption(title: "Favoritos",asset: "valoraciones.svg",),
                        SizedBox(
                          height: 16,
                        ),
                        Text("IDENTIFICACIÓN",  style: TextStyle(fontSize: 16),),
                        SizedBox(
                          height: 8,
                        ),
                        MenuOption(title: "Código QR",asset: "qr.svg",),
                        MenuOption(title: "Pasaporte",asset: "pasaporte.svg",),
                      ],
                    ),
                    ]
            ),
          ),
    )]));
  }
}

class MenuOption extends StatelessWidget {
  final String title;
  final String asset;
  final Widget page;

  const MenuOption({
    Key key,this.asset,this.title,this.page
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ()=> GlobalMethods().pushPage(context, page),
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
                      color: Colors.black,  // Color del icono
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(this.title,style: TextStyle(fontSize: 24),),
                  ),
                ],
              ), // Icono
              Icon(Icons.arrow_forward_ios_rounded,size: 16,)
              ],


            ),
            Padding(
              padding: const EdgeInsets.only(left: 32.0),
              child: Divider(color:Colors.black),
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

  const Pin({Key key, this.title,this.asset}) : super(key: key);


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
