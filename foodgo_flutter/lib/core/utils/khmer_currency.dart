class KhmerCurrency {
  /// Standard Cambodian retail exchange rate (NBC / Market customary average)
  static const double khrPerUsd = 4100.0;

  /// Formats USD amount with 2 decimal places: e.g. "$12.50"
  static String formatUsd(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  /// Formats equivalent in Khmer Riel with ៛ symbol and thousand separators: e.g. "៛51,250"
  static String formatKhr(double usdAmount) {
    final khrVal = (usdAmount * khrPerUsd).round();
    return '៛${_formatWithCommas(khrVal)}';
  }

  /// Formats dual currency: e.g. "$12.50 (៛51,250)"
  static String formatDual(double usdAmount) {
    return '${formatUsd(usdAmount)} (${formatKhr(usdAmount)})';
  }

  /// Formats dual currency with approximation sign: e.g. "$12.50 ≈ ៛51,250"
  static String formatDualApprox(double usdAmount) {
    return '${formatUsd(usdAmount)} ≈ ${formatKhr(usdAmount)}';
  }

  /// Converts USD to Cambodian Riel integer
  static int toKhr(double usdAmount) {
    return (usdAmount * khrPerUsd).round();
  }

  /// Converts Cambodian Riel to USD
  static double toUsd(int khrAmount) {
    return khrAmount / khrPerUsd;
  }

  static String _formatWithCommas(int value) {
    final str = value.toString();
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(regex, (m) => '${m[1]},');
  }
}
