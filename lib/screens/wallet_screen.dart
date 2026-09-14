import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:upi_payment_qrcode_generator/upi_payment_qrcode_generator.dart';
import '../config.dart';
import '../providers/currency_provider.dart';
import '../services/api_service.dart';
import '../theme.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double _balance = 0;
  bool _loading = true;
  List<Map<String, dynamic>> _myDeposits = [];

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeToUpdates();
  }

  Future<void> _load() async {
    try {
      final api = context.read<ApiService>();
      final supabase = Supabase.instance.client;

      final balance = await api.getBalance();
      final uid = supabase.auth.currentUser!.id;

      final deposits = await supabase
          .from('transactions')
          .select()
          .eq('user_id', uid)
          .eq('type', 'Deposit')
          .order('created_at', ascending: false)
          .limit(20);

      if (mounted) {
        setState(() {
          _balance = balance;
          _myDeposits = List<Map<String, dynamic>>.from(deposits);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _subscribeToUpdates() {
    final supabase = Supabase.instance.client;
    final uid = supabase.auth.currentUser!.id;

    supabase
        .channel('my-deposits')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: uid,
          ),
          callback: (payload) {
            _load();
          },
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    final cur = context.watch<CurrencyProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Wallet',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Balance card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Available Balance',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 10),
                        Text(cur.format(_balance),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1)),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _openAddFunds,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Funds',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  const Text('Deposit History',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 12),

                  if (_myDeposits.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.history,
                              color: AppColors.textMuted, size: 40),
                          SizedBox(height: 12),
                          Text('No deposits yet',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )
                  else
                    ..._myDeposits.map((d) => _DepositTile(deposit: d)),
                ],
              ),
      ),
    );
  }

  void _openAddFunds() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddFundsSheet(),
    );
  }
}

// ============================================================
// DEPOSIT TILE
// ============================================================
class _DepositTile extends StatelessWidget {
  final Map<String, dynamic> deposit;
  const _DepositTile({required this.deposit});

  @override
  Widget build(BuildContext context) {
    final cur = context.read<CurrencyProvider>();
    final status = deposit['status'] ?? 'Pending';
    final amount = double.tryParse(deposit['amount'].toString()) ?? 0;

    Color color;
    IconData icon;
    switch (status) {
      case 'Completed':
        color = AppColors.success;
        icon = Icons.check_circle;
        break;
      case 'Rejected':
        color = AppColors.error;
        icon = Icons.cancel;
        break;
      default:
        color = AppColors.warning;
        icon = Icons.hourglass_top;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cur.format(amount),
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  deposit['utr_number'] != null
                      ? 'UTR: ${deposit['utr_number']}'
                      : 'UPI Deposit',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status,
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ADD FUNDS SHEET
// ============================================================
class _AddFundsSheet extends StatefulWidget {
  const _AddFundsSheet();

  @override
  State<_AddFundsSheet> createState() => _AddFundsSheetState();
}

class _AddFundsSheetState extends State<_AddFundsSheet> {
  final _amountController = TextEditingController();
  final _utrController = TextEditingController();

  int _step = 1; // 1: enter amount, 2: show QR, 3: enter UTR
  double _selectedAmount = 100;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    _utrController.dispose();
    super.dispose();
  }

  void _generateQR() {
    final amt = double.tryParse(_amountController.text) ?? 0;
    if (amt < AppConfig.minDeposit) {
      setState(() => _error = 'Minimum ₹${AppConfig.minDeposit.toInt()}');
      return;
    }
    if (amt > AppConfig.maxDeposit) {
      setState(() => _error = 'Maximum ₹${AppConfig.maxDeposit.toInt()}');
      return;
    }
    setState(() {
      _selectedAmount = amt;
      _error = null;
      _step = 2;
    });
  }

  Future<void> _submitUTR() async {
    final utr = _utrController.text.trim();
    if (utr.length < 6) {
      setState(() => _error = 'Enter a valid UTR / Transaction ID');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final api = context.read<ApiService>();
      await api.submitDeposit(
        amount: _selectedAmount,
        utrNumber: utr,
      );

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Deposit submitted! Wait for admin approval — usually within 5 minutes.'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      setState(() {
        _submitting = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      _step == 1
                          ? 'Add Funds'
                          : _step == 2
                              ? 'Pay via UPI'
                              : 'Confirm Payment',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: _step == 1
                      ? _buildAmountStep()
                      : _step == 2
                          ? _buildQRStep()
                          : _buildUTRStep(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------- STEP 1 ----------
  Widget _buildAmountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Enter amount to deposit',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary),
          decoration: const InputDecoration(
            prefixText: '₹ ',
            prefixStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
            hintText: 'Min: ₹50 ~ Max: ₹2000',
          ),
        ),
        const SizedBox(height: 20),
        const Text('Quick select',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: AppConfig.quickAmounts.map((amt) {
            return GestureDetector(
              onTap: () {
                _amountController.text = amt.toInt().toString();
                setState(() {});
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: _amountController.text == amt.toInt().toString()
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _amountController.text == amt.toInt().toString()
                        ? AppColors.primary
                        : AppColors.border,
                    width: _amountController.text == amt.toInt().toString()
                        ? 1.5
                        : 1,
                  ),
                ),
                child: Text('₹${amt.toInt()}',
                    style: TextStyle(
                        color: _amountController.text ==
                                amt.toInt().toString()
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Text(
          'Min: ₹${AppConfig.minDeposit.toInt()} · Max: ₹${AppConfig.maxDeposit.toInt()}',
          style: const TextStyle(
              color: AppColors.textMuted, fontSize: 12),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          _ErrorBox(message: _error!),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _generateQR,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Generate UPI QR Code',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  // ---------- STEP 2 ----------
  Widget _buildQRStep() {
    final upiDetails = UPIDetails(
      upiID: AppConfig.upiId,
      payeeName: AppConfig.upiPayeeName,
      amount: _selectedAmount,
      transactionNote:
          'Fancrease_${DateTime.now().millisecondsSinceEpoch}',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pay ₹${_selectedAmount.toInt()} to continue',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Scan this QR with any UPI app',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'GPay  ·  PhonePe  ·  Paytm  ·  BHIM',
          textAlign: TextAlign.center,
          style:
              TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 20),
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: UPIPaymentQRCode(upiDetails: upiDetails),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _row('UPI ID', AppConfig.upiId),
              const Divider(color: AppColors.border, height: 20),
              _row('Amount', '₹${_selectedAmount.toInt()}'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: () => setState(() {
              _step = 3;
              _error = null;
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('I have paid — Continue',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() {
            _step = 1;
            _error = null;
          }),
          child: const Text('Change amount'),
        ),
      ],
    );
  }

  // ---------- STEP 3 ----------
  Widget _buildUTRStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle,
                  color: AppColors.success, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Great! Now enter the UTR / Transaction ID from your UPI app.',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('UTR / Transaction ID',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: _utrController,
          style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 15),
          decoration: const InputDecoration(
            hintText: 'e.g. 4235xxxx8912',
            prefixIcon: Icon(Icons.confirmation_number,
                color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Find this in your UPI app under "Transaction Details". It\'s a 12-digit number.',
          style: TextStyle(
              color: AppColors.textMuted, fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _row('Amount', '₹${_selectedAmount.toInt()}'),
              const Divider(color: AppColors.border, height: 20),
              _row('Status', 'Pending Approval'),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          _ErrorBox(message: _error!),
        ],
        const SizedBox(height: 20),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submitUTR,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              disabledBackgroundColor:
                  AppColors.primary.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Submit for Approval',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: AppColors.error, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}