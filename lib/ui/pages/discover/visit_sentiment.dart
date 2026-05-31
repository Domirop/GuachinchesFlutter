import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';

const Map<String, String> kSentimentLabels = {
  'muy_positivo': 'Muy bueno',
  'positivo': 'Bueno',
  'neutro': 'Neutro',
  'negativo': 'Flojo',
};

Color? sentimentColor(String s) {
  switch (s) {
    case 'muy_positivo':
      return AppColors.laurisilva;
    case 'positivo':
      return AppColors.atlantico;
    case 'neutro':
      return AppColors.arena;
    case 'negativo':
      return AppColors.mojo;
  }
  return null;
}
