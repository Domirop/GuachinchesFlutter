import 'dart:async';
import 'package:flutter/material.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/components/SurveyResults/SurveyResults.dart';
import 'package:guachinches/ui/components/cards/rankingCard.dart';
import 'package:guachinches/ui/pages/myVotedRestaurants/myVotedRestaurants.dart';
import 'package:guachinches/ui/pages/surveyDetails/surveyDetails.dart';
import 'package:guachinches/ui/pages/surveyRanking/surveyRankingPresenter.dart';
import 'package:http/http.dart';

class SurveyRanking extends StatefulWidget {
  final List<SurveyResult> guachinchesTradicionales;
  final List<SurveyResult> guachinchesModernos;
  final List<Restaurant> allRestaurants;
  final VoidCallback onRefresh;
  final bool isInitialTraditional;

  const SurveyRanking({
    Key? key,
    required this.guachinchesTradicionales,
    required this.guachinchesModernos,
    required this.isInitialTraditional,
    required this.allRestaurants,
    required this.onRefresh
  }) : super(key: key);

  @override
  State<SurveyRanking> createState() => _SurveyRankingState();
}

class _SurveyRankingState extends State<SurveyRanking> implements SurveyRankingView {
  late bool isTraditional;
  List<SurveyResult> localGuachinchesModernos = [];
  List<SurveyResult> localGuachinchesTradicionales = [];
  late RemoteRepository remoteRepository;
  late SurveyRankingPresenter presenter;
  List<String> userRestaurantsVoted = [];

  // Temporizador
  final DateTime endDate = DateTime(2025, 4, 20, 23, 59);
  late Timer countdownTimer;
  late Duration timeLeft;

  @override
  void initState() {
    super.initState();
    localGuachinchesModernos = widget.guachinchesModernos;
    localGuachinchesTradicionales = widget.guachinchesTradicionales;
    isTraditional = widget.isInitialTraditional;
    remoteRepository = HttpRemoteRepository(Client());
    presenter = SurveyRankingPresenter(this, remoteRepository);

    timeLeft = endDate.difference(DateTime.now());
    startCountdown();
  }

  void startCountdown() {
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      setState(() {
        timeLeft = endDate.difference(now);
        if (timeLeft.isNegative) {
          countdownTimer.cancel();
        }
      });
    });
  }

  String formatDuration(Duration duration) {
    if (duration.isNegative) return "Encuesta finalizada";
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    return '$days días, $hours h, $minutes min';
  }

  @override
  void dispose() {
    countdownTimer.cancel();
    super.dispose();
  }

  void _changeView(bool traditional) {
    setState(() {
      isTraditional = traditional;
    });
  }

  Future<void> _refreshData() async {
    await Future.delayed(const Duration(seconds: 1));
    presenter.getSurveyResults(widget.allRestaurants);
    widget.onRefresh.call();
  }

  @override
  Widget build(BuildContext context) {
    final currentData = isTraditional
        ? localGuachinchesTradicionales
        : localGuachinchesModernos;
    final top3 = currentData.take(3).toList();
    final others = currentData.skip(3).toList();
    final title = isTraditional ? "Guachinches Tradicionales" : "Guachinches Modernos";

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Resultado votaciones",
          style: TextStyle(fontFamily: "SF Pro Display"),
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 140),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                          child: Column(
                            children: [
                              Text(
                                '⏳ Tiempo restante: ${formatDuration(timeLeft)}',
                                key: ValueKey(timeLeft.toString()),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: "SF Pro Display",
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '📅 Fecha fin: 20 de abril de 2025',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: "SF Pro Display",
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 12),
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text("Tradicionales", style: TextStyle(fontFamily: "SF Pro Display")),
                          selected: isTraditional,
                          onSelected: (selected) {
                            if (!isTraditional) _changeView(true);
                          },
                          selectedColor: GlobalMethods.blueColor,
                          labelStyle: TextStyle(
                            color: isTraditional ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ChoiceChip(
                          label: const Text("Modernos", style: TextStyle(fontFamily: "SF Pro Display")),
                          selected: !isTraditional,
                          onSelected: (selected) {
                            if (isTraditional) _changeView(false);
                          },
                          selectedColor: GlobalMethods.blueColor,
                          labelStyle: TextStyle(
                            color: !isTraditional ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/encuesta_tradicional.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            title,
                            key: ValueKey(title),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: "SF Pro Display",
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const SizedBox(height: 10),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 700),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.0, 0.2),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            key: ValueKey('top3-$isTraditional'),
                            children: List.generate(top3.length, (index) {
                              var item = top3[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: RankingCard(
                                  position: index + 1,
                                  name: item.restaurant!.nombre,
                                  votes: item.votes.toString(),
                                  height: index == 0 ? 80 : 60,
                                  isWinner: index == 0,
                                  votedByUser: item.isVotedByUser,
                                  logoUrl: item.restaurant!.mainFoto,
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      children: List.generate(others.length, (index) {
                        var item = others[index];
                        int position = index + 4;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: RankingCard(
                            position: position,
                            name: item.restaurant!.nombre,
                            votes: item.votes.toString(),
                            height: 60,
                            isWinner: false,
                            votedByUser: item.isVotedByUser,
                            logoUrl: item.restaurant!.mainFoto,
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          /// BOTONES FLOTANTES
          Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                      elevation: 6,
                    ),
                    onPressed: () {
                      GlobalMethods().pushPage(
                          context,
                          MyVotedRestaurants(
                            tradicionales: localGuachinchesTradicionales,
                            modernos: localGuachinchesModernos,
                          ));
                    },
                    child: const Text(
                      'Ver mis votaciones',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: "SF Pro Display",
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromRGBO(0, 255, 102, 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                      elevation: 6,
                    ),
                    onPressed: () async {
                      await GlobalMethods().pushPageAsync(
                        context,
                        SurveyDetails(onRefresh: _refreshData),
                      );
                      _refreshData();
                    },
                    child: const Text(
                      'Votar',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: "SF Pro Display",
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void setSurveyResults(List<SurveyResult> guachinchesModernos, List<SurveyResult> guachinchesTradicionales) {
    setState(() {
      localGuachinchesTradicionales = guachinchesTradicionales;
      localGuachinchesModernos = guachinchesModernos;
    });
  }
}
