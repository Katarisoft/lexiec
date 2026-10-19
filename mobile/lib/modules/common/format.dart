/// Fecha local en formato dd/mm/aaaa, o «—» si no se conoce.
String formatDate(DateTime? date) {
  if (date == null) return '—';
  final local = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year}';
}
