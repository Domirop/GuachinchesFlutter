import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/login/login.dart';
import 'package:guachinches/ui/pages/valoraciones/valoraciones_presenter.dart';
import 'package:http/http.dart';

class MisVisitasPage extends StatefulWidget {
  @override
  _MisVisitasPageState createState() => _MisVisitasPageState();
}

class _MisVisitasPageState extends State<MisVisitasPage> {

  @override
  void initState() {
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CupertinoPageScaffold(
          child: CustomScrollView(
            slivers: [
              const CupertinoSliverNavigationBar(
                largeTitle: Text('Mis visitas'),
              ),
              SliverFillRemaining(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top:32.0),
                      child: Center(child: Text('Sin visitas')),
                    ),
                    SizedBox(height: 20.0),
                  ],
                ),
              )
            ],
          )
      ),
    );
  }

}
