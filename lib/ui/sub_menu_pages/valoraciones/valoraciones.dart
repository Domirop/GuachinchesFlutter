import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/main/login/login.dart';
import 'package:guachinches/ui/sub_menu_pages/valoraciones/valoraciones_presenter.dart';
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
                  return  Column(children:
                  state.user.valoraciones.map((e) => Padding(
                    padding: EdgeInsets.only(top:8.0),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                     e.title != null && e.title.isNotEmpty ? e.title : "Tu valoración",
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
                              ),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    SizedBox(
                                      height: 5.0,
                                    ),
                                    Text(
                                      e.restaurantes.nombre,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 20.0,
                          ),
                          Text(
                            e.review != null ? e.review : "",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14.0,
                            ),
                          ),
                          SizedBox(
                            height: 20.0,
                          ),
                        ],
                      ),
                    ),
                  )).toList());
                }else{
                  return Container();
                }
              }
            ),
            SizedBox(height: 20.0),
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
