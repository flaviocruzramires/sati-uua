class PaginatedResult<T> {
  final List<T> data;
  final int total;
  final int page;
  final int pageSize;

  const PaginatedResult({
    required this.data,
    required this.total,
    required this.page,
    required this.pageSize,
  });
}
