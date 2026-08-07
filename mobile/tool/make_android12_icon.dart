// Ferramenta de build: gera a imagem do ícone da splash do Android 12+.
//
// O Android 12 mascara a imagem da splash num círculo e exige que a arte
// caiba num círculo de 768px num canvas de 1152px. A logo cheia (com o anel,
// a árvore e o prédio) preenche toda a arte, então a máscara corta as bordas.
//
// Este script recorta APENAS o emblema circular (sem o texto "SATI-UUA"),
// faz o crop apertado e centraliza numa área segura, com margem, num canvas
// 1152×1152 transparente.
//
// Uso: dart run tool/make_android12_icon.dart
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final srcPath = '../imagens/SATI-UUA_1024.png';
  final outPath = 'assets/images/sati_icon_android12.png';

  final bytes = File(srcPath).readAsBytesSync();
  final src = img.decodePng(bytes)!;
  final w = src.width, h = src.height;

  int alphaAt(int x, int y) => src.getPixel(x, y).a.toInt();

  // 1) Bandas verticais de conteúdo (linhas com algum pixel opaco).
  const th = 15;
  final bands = <List<int>>[];
  bool inBand = false;
  int start = 0;
  for (var y = 0; y < h; y++) {
    var maxA = 0;
    for (var x = 0; x < w; x += 3) {
      final a = alphaAt(x, y);
      if (a > maxA) maxA = a;
    }
    final content = maxA > th;
    if (content && !inBand) {
      inBand = true;
      start = y;
    } else if (!content && inBand) {
      inBand = false;
      bands.add([start, y - 1]);
    }
  }
  if (inBand) bands.add([start, h - 1]);
  stdout.writeln('Bandas de conteúdo (linhas): $bands');

  // Primeira banda a partir do topo = emblema circular.
  final emblem = bands.first;
  final y0 = emblem[0], y1 = emblem[1];

  // 2) Limites horizontais apertados dentro da banda do emblema.
  int left = w, right = 0, top = h, bottom = 0;
  for (var y = y0; y <= y1; y++) {
    for (var x = 0; x < w; x++) {
      if (alphaAt(x, y) > th) {
        if (x < left) left = x;
        if (x > right) right = x;
        if (y < top) top = y;
        if (y > bottom) bottom = y;
      }
    }
  }
  final cropW = right - left + 1;
  final cropH = bottom - top + 1;
  stdout.writeln('Emblema bbox: x=$left..$right y=$top..$bottom ($cropW×$cropH)');

  final emblemImg = img.copyCrop(src, x: left, y: top, width: cropW, height: cropH);

  // 3) Canvas 1152×1152, arte dentro de um círculo seguro (~720px de lado).
  const canvas = 1152;
  const safe = 720; // < 768 exigido, com folga
  final scale = safe / (cropW > cropH ? cropW : cropH);
  final newW = (cropW * scale).round();
  final newH = (cropH * scale).round();
  final resized = img.copyResize(emblemImg, width: newW, height: newH,
      interpolation: img.Interpolation.cubic);

  final out = img.Image(width: canvas, height: canvas, numChannels: 4);
  // canvas totalmente transparente
  img.compositeImage(out, resized,
      dstX: ((canvas - newW) / 2).round(), dstY: ((canvas - newH) / 2).round());

  File(outPath).writeAsBytesSync(img.encodePng(out));
  stdout.writeln('Gerado: $outPath (emblema $newW×$newH em canvas $canvas)');
}
