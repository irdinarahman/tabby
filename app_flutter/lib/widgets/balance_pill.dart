import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Renders a signed balance: teal/"+" when the person is owed money,
/// coral/"−" when they owe money. Never show a raw signed number without
/// this treatment — the brief is explicit that users shouldn't have to
/// interpret accounting sign conventions themselves.
class BalancePill extends StatelessWidget {
  final double value;
  final bool large;

  const BalancePill({super.key, required this.value, this.large = false});

  @override
  Widget build(BuildContext context) {
    final owed = value >= 0;
    return Text(
      '${owed ? '+' : '\u2212'}${formatCurrency(value)}',
      style: TextStyle(
        fontFamily: 'Sora',
        fontWeight: FontWeight.w600,
        fontSize: large ? 26 : 15,
        color: owed ? AppColors.teal : AppColors.coral,
      ),
    );
  }
}
