import 'package:intl/intl.dart';

class Formatters {
  static final _money = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);
  static final _dateTime = DateFormat('EEE, dd MMM yyyy • hh:mm a');

  static String money(num value) => _money.format(value);
  static String dateTime(DateTime dt) => _dateTime.format(dt);
}
