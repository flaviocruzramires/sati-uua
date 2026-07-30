import 'package:flutter/material.dart';

abstract final class AppColors {
  // Accent — Navy (primária)
  static const navy = Color(0xFF1C3F6E);
  static const navyHover = Color(0xFF2C5085); // accent-500
  static const navyPressed = Color(0xFF142E52); // accent-700
  static const accent100 = Color(0xFFEAF0F8);
  static const accent200 = Color(0xFFCBDAEC);
  static const accent300 = Color(0xFF9EBAD9);
  static const accent400 = Color(0xFF6089B8);
  static const accent500 = Color(0xFF2C5085);
  static const accent600 = Color(0xFF1C3F6E);
  static const accent700 = Color(0xFF142E52);
  static const accent800 = Color(0xFF0D2038);
  static const accent900 = Color(0xFF081526);

  // Accent-2 — Verde (secundária / status positivo)
  static const green = Color(0xFF3E7A34);
  static const green100 = Color(0xFFEAF3E7);
  static const green200 = Color(0xFFCDE3C6);
  static const green300 = Color(0xFFA3CC98);
  static const green400 = Color(0xFF6FAD5F);
  static const green500 = Color(0xFF4E8F42);
  static const green600 = Color(0xFF3E7A34);
  static const green700 = Color(0xFF2F5F28);
  static const green800 = Color(0xFF23481E);
  static const green900 = Color(0xFF17300F);

  // Neutros / superfícies
  static const bg = Color(0xFFF4F5F7);
  static const surface = Color(0xFFE9EBEF);
  static const text = Color(0xFF1B1E24);
  static const divider = Color(0x661B1E24); // 40%
  static const neutral100 = Color(0xFFF5F6F8);
  static const neutral200 = Color(0xFFE7E9ED);
  static const neutral300 = Color(0xFFD3D7DE);
  static const neutral400 = Color(0xFFB3B9C4);
  static const neutral500 = Color(0xFF8B93A3);
  static const neutral600 = Color(0xFF6B7385);
  static const neutral700 = Color(0xFF4F5563);
  static const neutral800 = Color(0xFF383C46);
  static const neutral900 = Color(0xFF23262D);

  // Status situação — não usar diretamente, via AppTag
  static const muted = neutral600;
  static const label = neutral700;
}
