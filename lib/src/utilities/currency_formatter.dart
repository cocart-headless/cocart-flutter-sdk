import 'dart:math';

/// Formats raw integer amounts into currency strings using API currency data.
///
/// Mirrors the TS SDK's `CurrencyFormatter`.
class CurrencyFormatter {
  /// Formats a raw integer amount (e.g. 4599) into a currency string ("$45.99")
  /// using the currency object returned from the API.
  String format(int amount, Map<String, dynamic> currency) {
    final decimals = (currency['currency_minor_unit'] as int?) ?? 2;
    final symbol = (currency['currency_symbol'] as String?) ?? '';
    final position =
        (currency['currency_symbol_position'] as String?) ?? 'left';
    final decimalSep =
        (currency['currency_decimal_separator'] as String?) ?? '.';
    final thousandSep =
        (currency['currency_thousand_separator'] as String?) ?? ',';

    final value = amount / pow(10, decimals);
    final formatted =
        _formatNumber(value, decimals, decimalSep, thousandSep);

    return position == 'left' ? '$symbol$formatted' : '$formatted$symbol';
  }

  /// Formats a raw integer amount to a plain decimal string.
  String formatDecimal(int amount, Map<String, dynamic> currency) {
    final decimals = (currency['currency_minor_unit'] as int?) ?? 2;
    final value = amount / pow(10, decimals);
    return value.toStringAsFixed(decimals);
  }

  String _formatNumber(
      double value, int decimals, String decSep, String thouSep) {
    final parts = value.toStringAsFixed(decimals).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => thouSep,
    );
    return decimals > 0 ? '$intPart$decSep${parts[1]}' : intPart;
  }
}
