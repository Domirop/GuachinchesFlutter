import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/CuponesUser.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/components/history_full_page/coupon_details_presenter.dart';
import 'package:guachinches/ui/pages/splash_screen/splash_screen.dart';
import 'package:http/http.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CuponDetails extends StatefulWidget {
  String couponId;
  String userId;

  CuponDetails(this.couponId, this.userId);

  @override
  _CuponDetailsState createState() => _CuponDetailsState();
}

class _CuponDetailsState extends State<CuponDetails> implements CouponDetailsView{
  CuponesUser cuponUser;
  CouponDetailsPresenter presenter;
  RemoteRepository remoteRepository;

  @override
  void initState() {
    super.initState();
    remoteRepository = HttpRemoteRepository(Client());
    presenter = CouponDetailsPresenter(this, remoteRepository);

    presenter.getCoupon(widget.userId, widget.couponId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: cuponUser!=null?Container(
          child: Column(
            children: [
              Container(
                height: 300,
                child: Stack(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: 161,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          repeat: ImageRepeat.noRepeat,
                          alignment: Alignment.center,
                          fit: BoxFit.cover,
                          image: AssetImage('assets/images/fotocupones.png'),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Cupón confirmado",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          )
                        ],
                      ),
                    ),
                    Positioned(
                      top: 140,
                      child: Container(
                        height: 150,
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        width: MediaQuery.of(context).size.width - 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 5,
                              blurRadius: 7,
                              offset:
                              Offset(0, 3), // changes position of shadow
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  repeat: ImageRepeat.noRepeat,
                                  alignment: Alignment.center,
                                  fit: BoxFit.cover,
                                  image: NetworkImage(
                                      cuponUser.cupon.fotoUrl),
                                ),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              width: MediaQuery.of(context).size.width / 3.5,
                              height: 105,
                            ),
                            Flexible(
                              child: Container(
                                margin: EdgeInsets.only(left: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      cuponUser.cupon.restaurantName,
                                      style: TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 8.0,
                                    ),
                                    SizedBox(
                                      height: 8.0,
                                    ),
                                    Text(
                                      '',
                                      style: TextStyle(
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                width: MediaQuery.of(context).size.width - 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                    border: Border.all(color: Color.fromRGBO(0, 189, 195, 1),width: 2),
                    borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      Text('Felicidades, tu cupón ha sido reservado',style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold
                      ),),
                      Center(
                        child: QrImage(
                          data: "https://guachinchesmodernos.com/cupones/check/" + cuponUser.id,
                          version: QrVersions.auto,
                          size: MediaQuery.of(context).size.width*0.6,
                          padding: EdgeInsets.only(top:12.0),
                          gapless: true,
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top:6.0),
                          child: Text('Ver detalles',style: TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold
                          ),),
                        ),
                      ),
                      SizedBox(
                        height: 24,
                      ),

                      Text(
                          'Descuento: -'+cuponUser.cupon.descuento.toString()+'%',
                        style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),

                      ),
                      Text(
                        'Fecha: '+cuponUser.cupon.minDate,
                        style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),

                      ),
                      SizedBox(
                        height: 6,
                      ),
                      Text(
                        'Hemos enviado una copia de este cupón a tu correo electronico, también puedes acceder a el en tu perfil',
                        style: TextStyle(
                          fontSize: 12
                        ),
                      ),
                    SizedBox(
                      height: 8,
                    ),
                      Center(
                        child: Text(
                          '*Términos y condiciones de cupones',
                          style: TextStyle(
                            fontSize: 10
                          ),
                        ),
                      ),

                    ]
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                  onPressed: ()=>{
                    GlobalMethods().pushAndReplacement(context, SplashScreen())
                  }, child: Text('Volver al inicio')),
              TextButton(
                onPressed: ()=>{},
                child:
                Text('Candelar cupón',style: TextStyle(
                  color: Colors.red
                ),),

              ),
              SizedBox(height: 32),

            ],
          ),
        ):Center(child: SpinKitFadingCircle(color: Colors.blue,),),
      ),
    );
  }

  @override
  setCouponData(CuponesUser coupon) {
    setState(() {
      this.cuponUser = coupon;
    });
  }
}
