// =============================================================================
// SATI-UUA — Design Tokens em Dart (colar em mobile/lib/core/theme/)
// Fonte: docs-design/00-design-tokens.md (paleta do logo_sati_uua.jpg).
// Regra: nenhuma cor/estilo "hardcoded" fora deste tema.
// =============================================================================

import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// app_colors.dart
// -----------------------------------------------------------------------------
class AppColors {
  AppColors._();

  // Accent — Navy (primária: ação, navegação, links)
  static const accent    = Color(0xFF1C3F6E); // base UI
  static const accent100 = Color(0xFFEAF0F8);
  static const accent200 = Color(0xFFCBDAEC);
  static const accent300 = Color(0xFF9EBAD9);
  static const accent400 = Color(0xFF6089B8);
  static const accent500 = Color(0xFF2C5085);
  static const accent600 = Color(0xFF1C3F6E); // hover
  static const accent700 = Color(0xFF142E52); // pressed / texto sobre tint
  static const accent800 = Color(0xFF0D2038);
  static const accent900 = Color(0xFF081526);

  // Accent-2 — Verde (secundária / status positivo)
  static const green     = Color(0xFF3E7A34); // base
  static const green100  = Color(0xFFEAF3E7);
  static const green200  = Color(0xFFCDE3C6);
  static const green300  = Color(0xFFA3CC98);
  static const green400  = Color(0xFF6FAD5F);
  static const green500  = Color(0xFF4E8F42);
  static const green600  = Color(0xFF3E7A34);
  static const green700  = Color(0xFF2F5F28);
  static const green800  = Color(0xFF23481E);
  static const green900  = Color(0xFF17300F);

  // Neutros / superfícies
  static const bg      = Color(0xFFF4F5F7); // fundo da página / Scaffold
  static const surface = Color(0xFFE9EBEF); // cards, inputs, sidebar
  static const text    = Color(0xFF1B1E24); // texto principal
  static const divider = Color(0x661B1E24); // 40% — réguas 2px

  static const neutral100 = Color(0xFFF5F6F8);
  static const neutral200 = Color(0xFFE7E9ED); // trilha de barra / canvas
  static const neutral300 = Color(0xFFD3D7DE);
  static const neutral400 = Color(0xFFB3B9C4);
  static const neutral500 = Color(0xFF8B93A3); // desabilitado
  static const neutral600 = Color(0xFF6B7385); // texto secundário/meta
  static const neutral700 = Color(0xFF4F5563); // rótulos
  static const neutral800 = Color(0xFF383C46);
  static const neutral900 = Color(0xFF23262D);
}

// -----------------------------------------------------------------------------
// Cores de status (situação do chamado, papel, ativo/inativo)
// Use SEMPRE via os widgets de tag/chip — não recolorir ad-hoc.
// -----------------------------------------------------------------------------
enum SituacaoChamado { aberto, emAndamento, aguardandoSolicitante, encerrado }

class StatusColors {
  StatusColors._();

  // (fundo, texto) para chips de situação
  static (Color, Color) situacao(SituacaoChamado s) => switch (s) {
        SituacaoChamado.aberto                => (AppColors.accent100, AppColors.accent800),
        SituacaoChamado.emAndamento           => (AppColors.green100,  AppColors.green800),
        SituacaoChamado.aguardandoSolicitante => (Colors.transparent,  AppColors.accent), // outline
        SituacaoChamado.encerrado             => (AppColors.neutral100, AppColors.neutral800),
      };

  // Papel: ADMIN=accent, ATENDENTE=green, SOLICITANTE=neutral
  // Ativo=green, Inativo=neutral
}

// -----------------------------------------------------------------------------
// app_spacing.dart — spacing / raio / elevação
// -----------------------------------------------------------------------------
class AppSpacing {
  AppSpacing._();
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s6 = 24.0;
  static const s8 = 32.0;

  static const radius = 0.0; // Modernist: sem cantos arredondados
  static const rule   = 2.0; // réguas/bordas de seção (2px)

  static const shadowSm = [BoxShadow(color: Color(0x24232B2D), blurRadius: 2,  offset: Offset(0, 1))];
  static const shadowMd = [BoxShadow(color: Color(0x29232B2D), blurRadius: 10, offset: Offset(0, 3))];
  static const shadowLg = [BoxShadow(color: Color(0x38232B2D), blurRadius: 32, offset: Offset(0, 12))];
}

// -----------------------------------------------------------------------------
// app_theme.dart — ThemeData único do app (Material 3)
// Fonte 'Archivo' via pubspec (assets) ou google_fonts.
// -----------------------------------------------------------------------------
class AppTheme {
  AppTheme._();

  static const _zero = RoundedRectangleBorder(borderRadius: BorderRadius.zero);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: 'Archivo',
        scaffoldBackgroundColor: AppColors.bg,
        dividerColor: AppColors.divider,
        colorScheme: const ColorScheme.light(
          primary: AppColors.accent,
          onPrimary: AppColors.bg,
          secondary: AppColors.green,
          onSecondary: AppColors.bg,
          surface: AppColors.surface,
          onSurface: AppColors.text,
          outline: AppColors.divider,
        ),

        textTheme: const TextTheme(
          // headings 800
          displaySmall:   TextStyle(fontSize: 42, fontWeight: FontWeight.w800, letterSpacing: -0.6, height: 1.12),
          headlineMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.12),
          headlineSmall:  TextStyle(fontSize: 25, fontWeight: FontWeight.w800, letterSpacing: -0.4, height: 1.12),
          titleLarge:     TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.15),
          titleMedium:    TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          // body 400
          bodyLarge:  TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: 1.55, color: AppColors.text),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5,  color: AppColors.text),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w800), // rótulo de botão
          labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.neutral700),
        ),

        cardTheme: CardTheme(
          color: AppColors.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: _zero,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border:        const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.divider)),
          enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.divider)),
          focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.accent, width: 2)),
          labelStyle: const TextStyle(fontSize: 12, color: AppColors.neutral700),
        ),

        // Botão primário: fundo navy, texto bg, raio 0, rótulo à esquerda.
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.bg,
            elevation: 0,
            shape: _zero,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ).copyWith(
            overlayColor: WidgetStateProperty.all(AppColors.accent700), // hover/pressed
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.text,
            shape: _zero,
            side: const BorderSide(color: AppColors.divider),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),

        segmentedButtonTheme: const SegmentedButtonThemeData(
          style: ButtonStyle(shape: WidgetStatePropertyAll(_zero)),
        ),

        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: AppSpacing.rule,
          space: AppSpacing.rule,
        ),

        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.accent,
        ),
      );
}

// -----------------------------------------------------------------------------
// NOTA: 'Archivo' precisa estar no pubspec.yaml, ex.:
// flutter:
//   fonts:
//     - family: Archivo
//       fonts:
//         - asset: assets/fonts/Archivo-Regular.ttf
//         - asset: assets/fonts/Archivo-Bold.ttf
//           weight: 800
// (ou usar o pacote google_fonts com GoogleFonts.archivoTextTheme()).
// -----------------------------------------------------------------------------
