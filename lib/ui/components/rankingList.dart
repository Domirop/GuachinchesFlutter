import 'dart:async';
import 'package:flutter/material.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/components/SurveyResults/SurveyResults.dart';
import 'package:guachinches/ui/components/cards/rankingCard.dart';
import 'package:guachinches/ui/pages/surveyRanking/surveyRanking.dart';

class RankingList extends StatefulWidget {
  final List<SurveyResult> guachinchesModernos;
  final List<SurveyResult> guachinchesTradicionales;
  final List<Restaurant> allRestaurants;
  final VoidCallback onRefresh;

  const RankingList({
    Key? key,
    required this.guachinchesModernos,
    required this.guachinchesTradicionales,
    required this.allRestaurants,
    required this.onRefresh
  }) : super(key: key);

  @override
  State<RankingList> createState() => _RankingListState();
}

class _RankingListState extends State<RankingList> {
  bool isTraditional = true;
  late Timer _switchTimer;
  late Timer _countdownTimer;
  final DateTime endDate = DateTime(2025, 4, 20, 23, 59);
  late Duration timeLeft;

  @override
  void initState() {
    super.initState();
    _startAutoSwitchTimer();
    timeLeft = endDate.difference(DateTime.now());
    _startCountdownTimer();
  }

  void _startAutoSwitchTimer() {
    _switchTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      setState(() {
        isTraditional = !isTraditional;
      });
    });
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        timeLeft = endDate.difference(DateTime.now());
        if (timeLeft.isNegative) {
          _countdownTimer.cancel();
        }
      });
    });
  }

  String formatDuration(Duration duration) {
    if (duration.isNegative) return "Encuesta finalizada";
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    return "$days días, $hours h, $minutes min";
  }

  void _changeView(bool traditional) {
    setState(() {
      isTraditional = traditional;
      _switchTimer.cancel();
      _startAutoSwitchTimer();
    });
  }

  @override
  void dispose() {
    _switchTimer.cancel();
    _countdownTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = isTraditional ? "Guachinches Tradicionales" : "Guachinches Modernos";
    final List<SurveyResult> guachinchesActivos = isTraditional
        ? widget.guachinchesTradicionales
        : widget.guachinchesModernos;
    final List<SurveyResult> top3 = guachinchesActivos.take(3).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
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
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 12.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 4),
                        const Text(
                          '📅 Fecha fin: 20 de abril de 2025',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            fontFamily: "SF Pro Display",
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),


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
                  key: ValueKey(isTraditional),
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
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GestureDetector(
                  onTap: () {
                    GlobalMethods().pushPage(
                      context,
                      SurveyRanking(
                        guachinchesTradicionales: widget.guachinchesTradicionales,
                        guachinchesModernos: widget.guachinchesModernos,
                        isInitialTraditional: isTraditional,
                        allRestaurants: widget.allRestaurants,
                        onRefresh: widget.onRefresh,
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(37, 37, 43, 1),
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                    ),
                    height: 72,
                    child: const Center(
                      child: Text(
                        "Ver más",
                        style: TextStyle(
                          fontFamily: "SF Pro Display",
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}
