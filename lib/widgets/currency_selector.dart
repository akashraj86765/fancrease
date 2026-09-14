import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../models/currency.dart';
import '../theme.dart';

class CurrencySelectorButton extends StatelessWidget {
  const CurrencySelectorButton({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CurrencyProvider>();
    final cur = provider.selected;

    return PopupMenuButton<Currency>(
      tooltip: 'Change currency',
      color: AppColors.background,
      elevation: 8,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      onSelected: (c) => provider.setCurrency(c),
      itemBuilder: (ctx) => provider.all.map((c) {
        final selected = c.code == cur.code;
        return PopupMenuItem<Currency>(
          value: c,
          height: 44,
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Text(
                  c.code,
                  style: TextStyle(
                    color: selected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                c.symbol,
                style: TextStyle(
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (selected)
                const Icon(Icons.check,
                    color: AppColors.primary, size: 16),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${cur.symbol} ${cur.code}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down,
                size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}