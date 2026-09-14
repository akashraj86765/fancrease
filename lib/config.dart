class AppConfig {
  // ============================================================
  // SUPABASE
  // ============================================================
  static const String supabaseUrl = 'https://sghldauhiatdkbccdcle.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNnaGxkYXVoaWF0ZGtiY2NkY2xlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkxNTM2ODIsImV4cCI6MjEwNDcyOTY4Mn0.CO_ZIA3ZnkScXUCxd11ubbp3Q-dIyYFPFrInYrKEjjc';

  // ============================================================
  // UPI PAYMENT SETTINGS
  // ============================================================
  /// Your UPI ID (VPA). Example: 'fancrease@okhdfcbank'
  static const String upiId = 'akashraj8676@ybl';

  /// Business name shown in the UPI app
  static const String upiPayeeName = 'Fancrease Agency';

  /// Minimum deposit amount (INR)
  static const double minDeposit = 50.0;

  /// Maximum deposit amount (INR)
  static const double maxDeposit = 2000.0;

  /// Quick-select amounts shown as chips
  static const List<double> quickAmounts = [50, 100, 250, 500, 1000, 2000];
}