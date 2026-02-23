import 'package:flutter/material.dart';

class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double card = 16;
  static const double bottomSheet = 24;

  static BorderRadius get cardBorder => BorderRadius.circular(card);
  static BorderRadius get sheetBorder => BorderRadius.only(
        topLeft: Radius.circular(bottomSheet),
        topRight: Radius.circular(bottomSheet),
      );
}