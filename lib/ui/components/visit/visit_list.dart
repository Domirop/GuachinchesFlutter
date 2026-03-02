import 'package:flutter/material.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/visit/visit_screen.dart';

class VisitsHorizontalList extends StatelessWidget {
  final List<Visit> visits;

  const VisitsHorizontalList({Key? key, required this.visits}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (visits.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: const [
              Icon(Icons.play_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Últimas visitas recomendadas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'SF Pro Display',
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16, right: 8),
            itemCount: visits.length,
            itemBuilder: (context, index) {
              final visit = visits[index];
              return _VisitCard(visit: visit);
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _VisitCard extends StatelessWidget {
  final Visit visit;

  const _VisitCard({Key? key, required this.visit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasVideo = visit.videoUrl != null && visit.videoUrl!.isNotEmpty;
    final municipio = visit.restaurant?.municipio ?? '';

    return GestureDetector(
      onTap: () => GlobalMethods().pushPage(
        context,
        VisitDetailPage(visitId: visit.id),
      ),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color.fromRGBO(35, 37, 43, 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with play overlay
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Stack(
                children: [
                  // Image
                  if (visit.thumbnail != null && visit.thumbnail!.isNotEmpty)
                    Image.network(
                      visit.thumbnail!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      height: 140,
                      width: double.infinity,
                      color: const Color.fromRGBO(50, 50, 60, 1),
                      child: const Icon(Icons.image_not_supported,
                          color: Colors.white38, size: 32),
                    ),
                  // Play icon overlay (only if has video)
                  if (hasVideo)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.2),
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      visit.restaurant?.nombre ?? 'Sin nombre',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SF Pro Display',
                        height: 1.3,
                      ),
                    ),
                    if (municipio.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.grey, size: 11),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              municipio,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                                fontFamily: 'SF Pro Display',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
