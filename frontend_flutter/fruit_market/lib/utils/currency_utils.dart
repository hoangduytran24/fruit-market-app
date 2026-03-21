import 'package:intl/intl.dart';

class CurrencyUtils {
  static final NumberFormat _formatter = NumberFormat('#,###', 'vi_VN');

  static String format(double amount) {
    return '${_formatter.format(amount)}đ';
  }

  static String formatWithoutSymbol(double amount) {
    return _formatter.format(amount);
  }

  static double parse(String formatted) {
    return double.parse(formatted.replaceAll(RegExp(r'[^\d]'), ''));
  }
}