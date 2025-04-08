import 'dart:ffi';

import 'package:flutter/material.dart';

class RankingCard extends StatelessWidget {
  final int position;
  final String name;
  final String votes;
  final double height;
  final bool isWinner;
  final bool votedByUser;
  final String logoUrl;

  const RankingCard({
    Key? key,
    required this.position,
    required this.name,
    required this.votes,
    required this.height,
    this.votedByUser = false,
    this.isWinner = false,
    required this.logoUrl
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color leftBoxColor = isWinner ? Color.fromRGBO(51, 189, 236, 1) : Colors.grey.shade900;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: leftBoxColor,
            borderRadius: const BorderRadius.all(Radius.circular(16)
            ),
          ),
          height: height,
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0.0),
          child: Row(
            children: [
              // Caja para la posición
              Container(
                width: 32,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$position.',
                  style: const TextStyle(fontSize: 20, color: Colors.white,fontFamily: "SF Pro Display"),
                ),
              ),
              // Caja para nombre, logo y votos
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0,8,8,8),
                  child: Container(
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(37, 37, 43, 1),
                      borderRadius: const BorderRadius.all(Radius.circular(16)
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      children: [
                         CircleAvatar(
                          backgroundImage: NetworkImage(logoUrl),
                          radius: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(fontSize: 14, color: Colors.white,fontFamily: "SF Pro Display"),
                                overflow: TextOverflow.ellipsis,
                              ),
                              votedByUser?Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle_outline,color: Colors.lightGreenAccent,size: 12),
                                    Text(" Votado por mí",
                                      style: const TextStyle(fontSize: 10, color: Colors.white,fontFamily: "SF Pro Display"),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ):Container()
                            ],
                          ),
                        ),
                        Text(
                          '$votes Votos',
                          style: const TextStyle(fontSize: 10, color: Colors.white60,fontFamily: "SF Pro Display"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
