import '../model/Island.dart';

class AllIsland{
  List<Island> allIsland = [
    new Island('76ac0bec-4bc1-41a5-bc60-e528e0c12f4d', 'Tenerife.png', 'Tenerife'),
    new Island('6f91d60f-0996-4dde-9088-167aab83a21a', 'Gran_Canaria.png', 'Gran Canaria')
  ];
  getIslandById (String islandId){
    print(islandId);
    return allIsland.firstWhere((element) => element.id==islandId);
  }
}