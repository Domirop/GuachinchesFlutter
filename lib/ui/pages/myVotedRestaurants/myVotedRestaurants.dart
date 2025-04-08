import 'package:flutter/material.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/components/cards/rankingCard.dart';
import 'package:guachinches/ui/components/SurveyResults/SurveyResults.dart';

class MyVotedRestaurants extends StatelessWidget {
  final List<SurveyResult> tradicionales;
  final List<SurveyResult> modernos;

  const MyVotedRestaurants({
    Key? key,
    required this.tradicionales,
    required this.modernos,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final votedTradicionales =
    tradicionales.where((r) => r.isVotedByUser).toList();
    final votedModernos =
    modernos.where((r) => r.isVotedByUser).toList();

    final bool hasVoted = votedTradicionales.isNotEmpty || votedModernos.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Votaciones", style: TextStyle(fontFamily: "SF Pro Display")),
      ),
      body: hasVoted
          ? ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (votedTradicionales.isNotEmpty) ...[
            const Text(
              "Guachinches Tradicionales",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: "SF Pro Display",
              ),
            ),
            const SizedBox(height: 8),
            ...votedTradicionales.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RankingCard(
                  position: index + 1,
                  name: item.restaurant?.nombre ?? "Nombre no disponible",
                  votes: item.votes.toString(),
                  height: 60,
                  isWinner: false,
                  votedByUser: true,
                  logoUrl: item.restaurant!.mainFoto,
                ),
              );
            }).toList(),
            const SizedBox(height: 24),
          ],
          if (votedModernos.isNotEmpty) ...[
            const Text(
              "Guachinches Modernos",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: "SF Pro Display",
              ),
            ),
            const SizedBox(height: 8),
            ...votedModernos.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RankingCard(
                  position: index + 1,
                  name: item.restaurant?.nombre ?? "Nombre no disponible",
                  votes: item.votes.toString(),
                  height: 60,
                  isWinner: false,
                  votedByUser: true,
                  logoUrl: item.restaurant!.mainFoto,

                ),
              );
            }).toList(),
          ]
        ],
      )
          : const Center(
        child: Text(
          "Aún no has votado por ningún guachinche.",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
