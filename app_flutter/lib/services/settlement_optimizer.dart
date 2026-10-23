/// Client-side port of `App\Services\SettlementOptimizer` (see the Laravel
/// backend). Kept identical in behaviour so the settlement plan the app
/// shows optimistically (before a round-trip to the API) always matches
/// what the server would compute.
class SettlementSuggestionPlan {
  final String from;
  final String to;
  final double amount;

  SettlementSuggestionPlan({required this.from, required this.to, required this.amount});
}

class SettlementOptimizer {
  static const _epsilon = 0.01;

  List<SettlementSuggestionPlan> plan(Map<String, double> balances) {
    final creditors = <MapEntry<String, double>>[];
    final debtors = <MapEntry<String, double>>[];

    balances.forEach((id, amount) {
      if (amount > _epsilon) {
        creditors.add(MapEntry(id, amount));
      } else if (amount < -_epsilon) {
        debtors.add(MapEntry(id, -amount));
      }
    });

    creditors.sort((a, b) => b.value.compareTo(a.value));
    debtors.sort((a, b) => b.value.compareTo(a.value));

    final result = <SettlementSuggestionPlan>[];
    var i = 0, j = 0;
    final mutableCreditors = creditors.map((e) => MapEntry(e.key, e.value)).toList();
    final mutableDebtors = debtors.map((e) => MapEntry(e.key, e.value)).toList();

    while (i < mutableDebtors.length && j < mutableCreditors.length) {
      final amount = [mutableDebtors[i].value, mutableCreditors[j].value].reduce((a, b) => a < b ? a : b);
      final rounded = double.parse(amount.toStringAsFixed(2));

      if (rounded > _epsilon) {
        result.add(SettlementSuggestionPlan(from: mutableDebtors[i].key, to: mutableCreditors[j].key, amount: rounded));
      }

      mutableDebtors[i] = MapEntry(mutableDebtors[i].key, mutableDebtors[i].value - rounded);
      mutableCreditors[j] = MapEntry(mutableCreditors[j].key, mutableCreditors[j].value - rounded);

      if (mutableDebtors[i].value <= _epsilon) i++;
      if (mutableCreditors[j].value <= _epsilon) j++;
    }

    return result;
  }
}
