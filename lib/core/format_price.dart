String formatPesos(int priceCentavos) {
  final pesos = (priceCentavos ~/ 100).toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  final centavos = (priceCentavos % 100).toString().padLeft(2, '0');
  return '₱$pesos.$centavos';
}
