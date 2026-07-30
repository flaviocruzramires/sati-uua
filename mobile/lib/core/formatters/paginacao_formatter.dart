String paginacaoLabel(int page, int pageSize, int total) {
  if (total == 0) return 'Nenhum resultado';
  final start = (page - 1) * pageSize + 1;
  final end = (start + pageSize - 1).clamp(1, total);
  return 'Mostrando $start–$end de $total';
}
