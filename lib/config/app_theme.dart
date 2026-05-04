import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';

ThemeData get appDarkTheme => ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'SF Pro Display',
      scaffoldBackgroundColor: AppColors.base,
      appBarTheme: const AppBarTheme(
        color: AppColors.base,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.crema),
        actionsIconTheme: IconThemeData(color: AppColors.crema),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.crema),
        displayMedium: TextStyle(
          color: AppColors.crema,
          fontFamily: 'SF Pro Display',
          fontSize: 18,
        ),
        displaySmall: TextStyle(
          color: AppColors.crema,
          fontFamily: 'SF Pro Display',
        ),
        bodyLarge: TextStyle(color: AppColors.crema),
        bodyMedium: TextStyle(
          color: AppColors.crema,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        bodySmall: TextStyle(
          color: AppColors.crema,
          fontFamily: 'SF Pro Display',
          fontSize: 12,
        ),
      ),
      buttonTheme: const ButtonThemeData(minWidth: 5),
      dividerColor: Colors.black,
      primarySwatch: Colors.blue,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      extensions: const [BrandColors.dark],
    );

ThemeData get appLightTheme => ThemeData(
      brightness: Brightness.light,
      fontFamily: 'SF Pro Display',
      scaffoldBackgroundColor: AppColors.crema,
      appBarTheme: const AppBarTheme(
        color: AppColors.crema,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.ink),
        actionsIconTheme: IconThemeData(color: AppColors.ink),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.ink),
        displayMedium: TextStyle(
          color: AppColors.ink,
          fontFamily: 'SF Pro Display',
          fontSize: 18,
        ),
        displaySmall: TextStyle(
          color: AppColors.ink,
          fontFamily: 'SF Pro Display',
        ),
        bodyLarge: TextStyle(color: AppColors.ink),
        bodyMedium: TextStyle(
          color: AppColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        bodySmall: TextStyle(
          color: AppColors.ink,
          fontFamily: 'SF Pro Display',
          fontSize: 12,
        ),
      ),
      buttonTheme: const ButtonThemeData(minWidth: 5),
      dividerColor: AppColors.borderCream,
      primarySwatch: Colors.blue,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      extensions: const [BrandColors.light],
    );
