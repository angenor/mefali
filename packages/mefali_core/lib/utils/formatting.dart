/// Formate un montant en centimes vers FCFA avec separateur milliers.
String formatFcfa(int centimes) {
  final fcfa = (centimes / 100).round();
  final negative = fcfa < 0;
  final str = fcfa.abs().toString();
  final buffer = StringBuffer();
  if (negative) buffer.write('-');
  for (var i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(str[i]);
  }
  return '${buffer.toString()} FCFA';
}
