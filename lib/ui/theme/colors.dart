import 'package:flutter/material.dart';

abstract final class CustomColors {
  static const gray100 = Color(0xFFD9E1F2);
  static const gray200 = Color(0xFFAAB7D5);
  static const gray300 = Color(0xFF7381A0);
  static const gray400 = Color(0xFF525E7A);
  static const gray500 = Color(0xFF394155);
  static const gray600 = Color(0xFF252B3A);
  static const gray700 = Color(0xFF1D212A);
  static const gray800 = Color(0xFF171A21);
  static const gray900 = Color(0xFF0D0D0F);

  static const MaterialColor gray = MaterialColor(
    0xFF394155,
    <int, Color>{
      50: Color(0xFFFAFAFA), // not changed yet
      100: gray100,
      200: gray200,
      300: gray300,
      350: Color(0xFFD6D6D6), // not changed yet
      400: gray400,
      500: gray500,
      600: gray600,
      700: gray700,
      800: gray800,
      850: Color(0xFF303030), // not changed yet
      900: gray900,
    },
  );

  static const blue100 = Color(0xFFC3D5FD);
  static const blue200 = Color(0xFFA5C0FD);
  static const blue300 = Color(0xFF729AF8);
  static const blue400 = Color(0xFF5987F3);
  static const blue500 = Color(0xFF3467DF);
  static const blue600 = Color(0xFF1C47AB);
  static const blue700 = Color(0xFF10307A);

  static const MaterialColor blue = MaterialColor(
    0xFF3467DF,
    <int, Color>{
      100: blue100,
      200: blue200,
      300: blue300,
      400: blue400,
      500: blue500,
      600: blue600,
      700: blue700,
    },
  );

  static const Color skyBlue = Color(0xFF53D8FB);
  static const Color brightGreen = Color(0xFF5AFF15);

  static const red100 = Color(0xFFFFC7CB);
  static const red200 = Color(0xFFFE9AA1);
  static const red300 = Color(0xFFF25F72);
  static const red400 = Color(0xFFC92647);
  static const red500 = Color(0xFFA91E3C);
  static const red600 = Color(0xFF7A102C);
  static const red900 = Color(0xFF340411);

  static const MaterialColor red = MaterialColor(
    0xFFA91E3C,
    <int, Color>{
      100: red100,
      200: red200,
      300: red300,
      400: red400,
      500: red500,
      600: red600,
      900: red900,
    },
  );

  static const green100 = Color(0xFFE3FDD8);
  static const green500 = Color(0xFF358712);
  static const green600 = Color(0xFF255E0D);
  static const green900 = Color(0xFF103003);

  static const MaterialColor green = MaterialColor(
    0xFF358712,
    <int, Color>{
      100: green100,
      500: green500,
      600: green600,
      900: green900,
    },
  );

  static const Color loadRed = Color(0xFFBE2F43);
  static const Color loadOrange = Color(0xFFE57830);
  static const Color loadYellow = Color(0xFFBC9920);
  static const Color loadGreen = Color(0xFF378613);
}
