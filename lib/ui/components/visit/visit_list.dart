import 'package:flutter/material.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/visit/visit_screen.dart';

class VisitsHorizontalList extends StatelessWidget {
  final List<Visit> visits;

  const VisitsHorizontalList({Key? key, required this.visits}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Text(
            "Últimas visitas recomendadas",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              fontFamily: "SF Pro Display",
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: 220, // altura total más realista
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: visits.length,
            itemBuilder: (context, index) {
              final visit = visits[index];

              return GestureDetector(
                onTap: () => GlobalMethods().pushPage(
                  context,
                  VisitDetailPage(visitId: visit.id),
                ),
                child: Container(
                  width: 128,
                  margin: const EdgeInsets.only(left: 16, right: 0, bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: GlobalMethods.bgColor,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imagen
                      ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(12)),
                        child: visit.thumbnail != null &&
                            visit.thumbnail!.isNotEmpty
                            ? Image.network(
                          visit.thumbnail!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                            : Container(
                          height: 150,
                          color: Colors.grey[800],
                          child: const Icon(Icons.image, color: Colors.white70),
                        ),
                      ),

                      // Espacio
                      const SizedBox(height: 6),

                      // Nombre del restaurante
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: Text(
                          visit.restaurant?.nombre ?? "Sin nombre",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            fontFamily: "SF Pro Display",
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
