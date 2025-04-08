import 'package:flutter/material.dart';
import 'package:guachinches/data/model/Category.dart';

class CategoryImageCard extends StatefulWidget {
  final ModelCategory modelCategory;
  CategoryImageCard(this.modelCategory);

  @override
  State<CategoryImageCard> createState() => _CategoryImageCardState();
}

class _CategoryImageCardState extends State<CategoryImageCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 150,
      margin: const EdgeInsets.only(right: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage(widget.modelCategory.foto),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Texto centrado verticalmente y alineado a la izquierda con salto de línea
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0,top: 16),
              child: Text.rich(
                TextSpan(
                  children: widget.modelCategory.nombre
                      .split(' ') // Dividimos el texto en palabras
                      .map((word) => TextSpan(
                    text: '$word\n', // Agregamos un salto de línea después de cada palabra
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: "SF Pro Display",
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 4.0,
                          color: Colors.black,
                          offset: Offset(1.0, 1.0),
                        ),
                      ],
                    ),
                  ))
                      .toList(),
                ),
                textAlign: TextAlign.left, // Alineamos el texto a la izquierda
              ),
            ),
          ),
        ],
      ),
    );
  }
}