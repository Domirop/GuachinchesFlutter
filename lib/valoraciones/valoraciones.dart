import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user_cubit.dart';
import 'package:guachinches/data/cubit/user_state.dart';
import 'package:guachinches/edit_reviews/edit_reviews.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/login/login.dart';
import 'package:guachinches/valoraciones/valoraciones_presenter.dart';
import 'package:http/http.dart';

class Valoraciones extends StatefulWidget {
  @override
  _ValoracionesState createState() => _ValoracionesState();
}

class _ValoracionesState extends State<Valoraciones> implements ValoracionesView{
  RemoteRepository _remoteRepository;
  ValoracionesPresenter _presenter;
  @override
  void initState() {
    _remoteRepository = HttpRemoteRepository(Client());
    final userCubit = context.read<UserCubit>();
    _presenter = ValoracionesPresenter(this, _remoteRepository, userCubit);
    _presenter.isUserLogged();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              height: 50.0,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  "Mis Valoraciones",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 20.0,
            ),
            BlocBuilder<UserCubit, UserState>(
              builder: (context, state){
                if(state is UserLoaded){
                  print(state.user.valoraciones.length);
                  return  Column(children:
                  state.user.valoraciones.map((e) => Padding(
                    padding: const EdgeInsets.only(top:8.0),
                    child: Container(
                      padding: EdgeInsets.all(20.0),
                      margin: EdgeInsets.symmetric(horizontal: 10.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black54,
                              blurRadius: 5.0,
                              spreadRadius: 1.0,
                              offset: Offset(2.0, 4.0))
                        ],
                        borderRadius: BorderRadius.circular(17.0),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "\""+e.title+"\"",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        e.rating,
                                        style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      RatingBar.builder(
                                        ignoreGestures: true,
                                        initialRating: double.parse(e.rating),
                                        minRating: 1,
                                        direction: Axis.horizontal,
                                        allowHalfRating: true,
                                        itemCount: 5,
                                        itemSize: 20,
                                        glowColor: Colors.white,
                                        onRatingUpdate: (rating)=>{},
                                        itemPadding: EdgeInsets.symmetric(horizontal: 2.0),
                                        itemBuilder: (context, _) => Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  TextButton(
                                    onPressed:()=>{
                                      GlobalMethods().pushPage(context, EditReview(state.user.id, e))
                                    },
                                    child: Text(
                                      "Editar valoración",
                                      style: TextStyle(
                                        color: Color.fromRGBO(254, 192, 75, 1),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.0,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 5.0,
                                  ),
                                  Text(
                                    e.restaurantes.nombre,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14.0,
                                    ),
                                  ),
                                  Text(
                                    "20/02/2021",
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 10.0,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 20.0,
                          ),
                          // Row(
                          //   children: [
                          //     Container(
                          //       height: 56.0,
                          //       width: 56.0,
                          //       decoration: BoxDecoration(
                          //         image: DecorationImage(
                          //           repeat: ImageRepeat.noRepeat,
                          //           alignment: Alignment.center,
                          //           fit: BoxFit.cover,
                          //           image: AssetImage('assets/images/escaldon.png'),
                          //         ),
                          //       ),
                          //     ),
                          //     SizedBox(width: 10.0,),
                          //     Container(
                          //       height: 56.0,
                          //       width: 56.0,
                          //       decoration: BoxDecoration(
                          //         image: DecorationImage(
                          //           repeat: ImageRepeat.noRepeat,
                          //           alignment: Alignment.center,
                          //           fit: BoxFit.cover,
                          //           image: AssetImage('assets/images/escaldon.png'),
                          //         ),
                          //       ),
                          //     ),
                          //   ],
                          // ),
                          SizedBox(
                            height: 20.0,
                          ),
                          Text(
                            state.user.valoraciones[0].review,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14.0,
                            ),
                          ),
                          SizedBox(
                            height: 20.0,
                          ),
                          // Text(
                          //   "Ver más",
                          //   style: TextStyle(
                          //     fontSize: 12.0,
                          //     color: Color.fromRGBO(222, 99, 44, 1),
                          //     decoration: TextDecoration.underline,
                          //     decorationColor: Color.fromRGBO(222, 99, 44, 1),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  )).toList()
                    ,);
                }
                return Container();
              }
            ),
          ],
        ),
      ),
    );
  }

  @override
  goToLogin() {
    GlobalMethods().pushPage(context, Login("Inicia sesion para ver tus valoraciones"));
  }
}
