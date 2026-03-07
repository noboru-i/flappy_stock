String _addCommas(int absValue) {
  final str = absValue.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
    buffer.write(str[i]);
  }
  return buffer.toString();
}

String formatCurrency(double value) {
  final sign = value < 0 ? '-' : '';
  return '¥$sign${_addCommas(value.toInt().abs())}';
}

String formatNumber(double value) {
  final sign = value < 0 ? '-' : '';
  return '$sign${_addCommas(value.toInt().abs())}';
}
