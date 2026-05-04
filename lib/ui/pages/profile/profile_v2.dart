import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/theme/theme_cubit.dart';
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
    final brand = context.brand;
    return CupertinoPageScaffold(
      backgroundColor: brand.base,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            backgroundColor: brand.base,
            largeTitle: Text(
              'Mi Perfil',
              style: TextStyle(
                color: brand.textPrimary,
                fontFamily: 'SF Pro Display',
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BlocBuilder<UserCubit, UserState>(
                        builder: (context, state) {
                          UserInfo userInfo = UserInfo();
                          if (state is UserLoaded) {
                            userInfo = state.user;
                            if (userInfo.nombre.isNotEmpty) {
                              userInfo.nombre =
                                  userInfo.nombre[0].toUpperCase() +
                                      userInfo.nombre.substring(1);
                            }
                          }
                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.atlantico,
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(16.0),
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
                                        child: Text(
                                          userInfo.nombre.length > 0
                                              ? userInfo.nombre[0]
                                              : '',
                                          style: const TextStyle(
                                            fontFamily: 'SF Pro Display',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 32,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 24.0),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              userInfo.nombre,
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontFamily: 'SF Pro Display',
                                                color: brand.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              userInfo.apellidos,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontFamily: 'SF Pro Display',
                                                color: brand.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const _ThemeToggleRow(),
                      const SizedBox(height: 16),
                      Text(
                        "PERFIL",
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'SF Display Pro',
                          color: brand.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      MenuOption(title: "Valoraciones", asset: "valoraciones.svg", page: ValoracionesPage()),
                      MenuOption(title: "Mis visitas", asset: "rutas.svg", page: MisVisitasPage()),
                      MenuOption(title: "Favoritos", asset: "fav.svg", page: FavoritosPage()),
                      const SizedBox(height: 16),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Column(
                          children: [
                            TextButton(
                              onPressed: () => _presenter.logOut(),
                              child: Text(
                                'Cerrar sesion',
                                style: TextStyle(
                                  fontFamily: 'SF Pro Display',
                                  color: brand.textPrimary,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _presenter.deleteAccount(),
                              child: Text(
                                'Eliminar usuario',
                                style: TextStyle(
                                  fontFamily: 'SF Pro Display',
                                  color: brand.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  setUserInfo(UserInfo userInfo) {
    throw UnimplementedError();
  }

  @override
  goSplashScreen() {
    GlobalMethods().pushAndReplacement(context, SplashScreen());
  }

  @override
  updateCupones(List<Cupones> cupones) {
    throw UnimplementedError();
  }

  @override
  updateListSql(List<Restaurant> restaurants) {
    throw UnimplementedError();
  }
}

class _ThemeToggleRow extends StatelessWidget {
  const _ThemeToggleRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (_, mode) {
        final isDark = mode == ThemeMode.dark;
        final brand = context.brand;
        return SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    size: 24,
                    color: brand.textPrimary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Modo oscuro',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'SF Pro Display',
                      color: brand.textPrimary,
                    ),
                  ),
                ],
              ),
              CupertinoSwitch(
                value: isDark,
                activeColor: AppColors.atlantico,
                onChanged: (v) => context.read<ThemeCubit>().setMode(
                  v ? ThemeMode.dark : ThemeMode.light,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MenuOption extends StatelessWidget {
  final String title;
  final String asset;
  final Widget? page;

  const MenuOption({
    Key? key, required this.asset, required this.title, this.page,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return GestureDetector(
      onTap: () => GlobalMethods().pushPage(context, page!),
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
                        "assets/images/" + asset,
                        color: brand.textPrimary,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        this.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'SF Pro Display',
                          color: brand.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: brand.textPrimary,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 32.0),
              child: Divider(color: brand.border),
            ),
          ],
        ),
      ),
    );
  }
}

class Pin extends StatelessWidget {
  final String title;
  final String asset;

  const Pin({Key? key, required this.title, required this.asset}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        GlobalMethods().pushPageWithFocus(
          context,
          PinDetail(
            title: title,
            asset: asset,
            description: "Haz visitado algún restaurante dificil de llegar de esos que tienes que preguntar 20 veces antes de encontrarlo",
          ),
        );
      },
      child: Container(
        child: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Column(
            children: [
              Image.asset(
                asset,
                width: 64,
                height: 64,
              ),
              Text(title, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
