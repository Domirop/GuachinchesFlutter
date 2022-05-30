import 'package:bottom_sheet/bottom_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FiltersScreen extends StatelessWidget {
  List<Category> categories;

  FiltersScreen(this.categories);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: categories
          .map(
            (element) => Padding(
              padding: EdgeInsets.only(
                top: 16.0,
                right: 8.0,
                left: 8.0,
              ),
              child: GestureDetector(
                onTap: () => _openBottomSheetWithInfo(context),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: Image(
                      image: AssetImage("category"),
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  void _openBottomSheetWithInfo(BuildContext context) {
    showFlexibleBottomSheet<void>(
      isExpand: false,
      initHeight: 0.8,
      maxHeight: 0.8,
      context: context,
      builder: (context, controller, offset) {
        return _BottomSheet(controller,
        );
      },
    );
  }
}

class _BottomSheet extends StatelessWidget {
  final ScrollController controller;

  _BottomSheet(this.controller);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: ListView(
        controller: controller,
        shrinkWrap: true,
        children: [
          Text(
            "prueba",
            style: const TextStyle(
              fontSize: 25.0,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: Image(
              image: NetworkImage("https://louvre.s3.fr-par.scw.cloud/guachinches/184954223_928922927895837_779066988885510655_n.jpeg"),
            ),
          ),
          SizedBox(height: 16.0),
          Text(
            "prueba",
            style: const TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
