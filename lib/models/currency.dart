class Currency {
  final String code;
  final String symbol;
  final String name;
  final String flag;
  final double rate; // 1 INR = X of this currency

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
    required this.flag,
    required this.rate,
  });

  /// 1 INR = X foreign currency. Update periodically.
  static const List<Currency> all = [
    Currency(code: 'INR', symbol: '₹',   name: 'Indian Rupee',       flag: '🇮🇳', rate: 1.0),
    Currency(code: 'USD', symbol: '\$',  name: 'US Dollar',          flag: '🇺🇸', rate: 0.0119),
    Currency(code: 'EUR', symbol: '€',   name: 'Euro',               flag: '🇪🇺', rate: 0.0110),
    Currency(code: 'GBP', symbol: '£',   name: 'British Pound',      flag: '🇬🇧', rate: 0.0094),
    Currency(code: 'BRL', symbol: 'R\$', name: 'Brazilian Real',     flag: '🇧🇷', rate: 0.0648),
    Currency(code: 'CNY', symbol: '¥',   name: 'Chinese Yuan',       flag: '🇨🇳', rate: 0.0863),
    Currency(code: 'EGP', symbol: '£',   name: 'Egyptian Pound',     flag: '🇪🇬', rate: 0.5805),
    Currency(code: 'KRW', symbol: '₩',   name: 'South Korean Won',   flag: '🇰🇷', rate: 16.42),
    Currency(code: 'JPY', symbol: '¥',   name: 'Japanese Yen',       flag: '🇯🇵', rate: 1.79),
    Currency(code: 'AED', symbol: 'د.إ', name: 'UAE Dirham',         flag: '🇦🇪', rate: 0.0437),
    Currency(code: 'SAR', symbol: '﷼',   name: 'Saudi Riyal',        flag: '🇸🇦', rate: 0.0446),
    Currency(code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar',    flag: '🇨🇦', rate: 0.0162),
    Currency(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar',  flag: '🇦🇺', rate: 0.0181),
    Currency(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar',   flag: '🇸🇬', rate: 0.0160),
    Currency(code: 'MYR', symbol: 'RM',  name: 'Malaysian Ringgit',  flag: '🇲🇾', rate: 0.0535),
    Currency(code: 'IDR', symbol: 'Rp',  name: 'Indonesian Rupiah',  flag: '🇮🇩', rate: 189.5),
    Currency(code: 'PHP', symbol: '₱',   name: 'Philippine Peso',    flag: '🇵🇭', rate: 0.68),
    Currency(code: 'THB', symbol: '฿',   name: 'Thai Baht',          flag: '🇹🇭', rate: 0.42),
    Currency(code: 'VND', symbol: '₫',   name: 'Vietnamese Dong',    flag: '🇻🇳', rate: 302.5),
    Currency(code: 'BDT', symbol: '৳',   name: 'Bangladeshi Taka',   flag: '🇧🇩', rate: 1.43),
    Currency(code: 'PKR', symbol: '₨',   name: 'Pakistani Rupee',    flag: '🇵🇰', rate: 3.32),
    Currency(code: 'NPR', symbol: '₨',   name: 'Nepalese Rupee',     flag: '🇳🇵', rate: 1.60),
    Currency(code: 'LKR', symbol: 'Rs',  name: 'Sri Lankan Rupee',   flag: '🇱🇰', rate: 3.55),
    Currency(code: 'TRY', symbol: '₺',   name: 'Turkish Lira',       flag: '🇹🇷', rate: 0.40),
    Currency(code: 'RUB', symbol: '₽',   name: 'Russian Ruble',      flag: '🇷🇺', rate: 1.05),
    Currency(code: 'NGN', symbol: '₦',   name: 'Nigerian Naira',     flag: '🇳🇬', rate: 19.85),
    Currency(code: 'ZAR', symbol: 'R',   name: 'South African Rand', flag: '🇿🇦', rate: 0.216),
    Currency(code: 'MXN', symbol: 'Mex\$', name: 'Mexican Peso',     flag: '🇲🇽', rate: 0.213),
    Currency(code: 'ARS', symbol: 'ARS\$', name: 'Argentine Peso',   flag: '🇦🇷', rate: 11.93),
  ];

  static Currency fromCode(String code) {
    return all.firstWhere(
      (c) => c.code == code,
      orElse: () => all.first,
    );
  }

  double convert(double inrAmount) => inrAmount * rate;
}