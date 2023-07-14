import 'package:flutter/material.dart';
import 'package:guachinches/data/model/CuponesAgrupados.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/components/history_full_page/pre_save_cupon.dart';

class CuponesList extends StatelessWidget {
  List<CuponesAgrupados> cupones;
  String userId;

  CuponesList(this.cupones,this.userId);

  @override
  Widget build(BuildContext context) {
    print('userId2');
    print(userId);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        height: 220,
        width: double.infinity,
        alignment: Alignment.center,
        child: ListView.builder(
            shrinkWrap: true,
            primary: false,
            itemCount: 1,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context,index){
              return Wrap(
                alignment: WrapAlignment.start,
                children: [
                  GestureDetector(
                    onTap: ()=>{},
                    child: Padding(
                      padding: const EdgeInsets.only(left: 14.0),
                      child: Container(
                        height: 180,
                        width: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          color: Color(0xffffffff),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.grey,
                              offset: Offset(0.0, 1.0),
                              blurRadius: 0.8,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top:8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  height: 100,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 100,
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(6),
                                            image: DecorationImage(
                                                fit: BoxFit.fill,
                                                image: ExactAssetImage('assets/images/bg-norte-test.png',)
                                            )
                                        ),
                                      ),
                                      Container(width: 20,),
                                      Container(
                                        child: Expanded(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: ([
                                              Text(cupones[0].nombre,style: TextStyle(fontWeight: FontWeight.bold),),
                                              Text('Adeje'),
                                              Text('-'+cupones[0].cupones[0].descuento.toString()+'% descuento',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red
                                                ),
                                              )
                                            ]),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          primary: Color.fromRGBO(0, 189, 195, 1),
                                      ),
                                      onPressed: ()=>GlobalMethods().pushPage(
                                          context,
                                          PreSaveCupon(cupones[index],userId)),
                                      child: Text('Reservar')),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              );
            }),
      ),
    );
  }
}