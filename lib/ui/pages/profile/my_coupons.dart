import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MyCoupons extends StatefulWidget {
  const MyCoupons({Key? key}) : super(key: key);

  @override
  State<MyCoupons> createState() => _MyCouponsState();
}

class _MyCouponsState extends State<MyCoupons> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        child: CustomScrollView(
      slivers: [
        const CupertinoSliverNavigationBar(
          largeTitle: Text('Mis Cupones'),
        ),
        SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //asset image
                  Container(
                    height: MediaQuery.of(context).size.height * 0.114,
                    width: MediaQuery.of(context).size.width * 0.89,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/banner_cupones.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Text(
                    'SIN CANJEAR',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        decoration: TextDecoration.none),
                  ),
                  SizedBox(
                    height: 16,
                  ),

                  CouponListItem(),
                  Divider(thickness:0.2,color: Color.fromRGBO(118, 118, 118, 1),),
                  CouponListItem(),
                  Divider(thickness:0.2,color: Color.fromRGBO(118, 118, 118, 1),),

                  CouponListItem(),
                  SizedBox(
                    height: 16,
                  ),
                  Text(
                    'CANJEAR',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        decoration: TextDecoration.none),
                  ),
                ],
              ),
            )),
      ],
    ));
  }
}

class CouponListItem extends StatelessWidget {
  const CouponListItem({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: AssetImage(
                    'assets/images/trancao.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children:[
                Text(
                  'Martes trancao',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none),
                ),
                Text(
                  'Icod de los vinos',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      decoration: TextDecoration.none),
                )
              ],
            ),
          ),
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children:[
                Text(
                  '15 SEP 2023',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none),
                ),
                Text(
                  '-10% descuento',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                       fontWeight: FontWeight.normal,
                      decoration: TextDecoration.none),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
