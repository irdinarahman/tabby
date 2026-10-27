import '../services/current_user.dart';

class Member {
  final String id;
  final String? userId;
  final String displayName;

  Member({required this.id, required this.displayName, this.userId});

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      displayName: (json['user']?['name'] ?? json['display_name']) as String,
    );
  }
}

class ExpenseParticipant {
  final String tabMemberId;
  final double shareAmount;

  ExpenseParticipant({required this.tabMemberId, required this.shareAmount});

  factory ExpenseParticipant.fromJson(Map<String, dynamic> json) {
    return ExpenseParticipant(
      tabMemberId: json['tab_member_id'] as String,
      shareAmount: double.parse(json['share_amount'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'tab_member_id': tabMemberId,
        'share_amount': shareAmount,
      };
}

class Expense {
  final String id;
  final String description;
  final double amount;
  final String paidBy;
  final String splitMethod; // 'equal' | 'custom'
  final DateTime date;
  final String? notes;
  final List<ExpenseParticipant> participants;

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.splitMethod,
    required this.date,
    required this.participants,
    this.notes,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      description: json['description'] as String,
      amount: double.parse(json['amount'].toString()),
      paidBy: json['paid_by'] as String,
      splitMethod: json['split_method'] as String,
      date: DateTime.parse(json['expense_date'] as String),
      notes: json['notes'] as String?,
      participants: (json['participants'] as List<dynamic>? ?? [])
          .map((p) => ExpenseParticipant.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Settlement {
  final String id;
  final String paidBy;
  final String paidTo;
  final double amount;
  final DateTime settledAt;

  Settlement({
    required this.id,
    required this.paidBy,
    required this.paidTo,
    required this.amount,
    required this.settledAt,
  });

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      id: json['id'] as String,
      paidBy: json['paid_by'] as String,
      paidTo: json['paid_to'] as String,
      amount: double.parse(json['amount'].toString()),
      settledAt: DateTime.parse(json['settled_at'] as String),
    );
  }
}

class SettlementSuggestion {
  final String from;
  final String to;
  final double amount;

  SettlementSuggestion({required this.from, required this.to, required this.amount});

  factory SettlementSuggestion.fromJson(Map<String, dynamic> json) {
    return SettlementSuggestion(
      from: json['from'] as String,
      to: json['to'] as String,
      amount: double.parse(json['amount'].toString()),
    );
  }
}

class TabSummary {
  final String id;
  final String name;
  final String? description;
  final int memberCount;
  final double totalSpent;
  final double yourBalance;

  TabSummary({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.totalSpent,
    required this.yourBalance,
    this.description,
  });

  factory TabSummary.fromJson(Map<String, dynamic> json) {
    return TabSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      memberCount: json['member_count'] as int,
      totalSpent: double.parse(json['total_spent'].toString()),
      yourBalance: double.parse(json['your_balance'].toString()),
    );
  }
}

class TabDetail {
  final String id;
  final String name;
  final String? description;
  final List<Member> members;
  final List<Expense> expenses;
  final List<Settlement> settlements;
  final Map<String, double> balances;

  TabDetail({
    required this.id,
    required this.name,
    required this.members,
    required this.expenses,
    required this.settlements,
    required this.balances,
    this.description,
  });

  factory TabDetail.fromJson(Map<String, dynamic> json) {
    final tab = json['tab'] as Map<String, dynamic>;
    final balancesJson = json['balances'] as Map<String, dynamic>;

    return TabDetail(
      id: tab['id'] as String,
      name: tab['name'] as String,
      description: tab['description'] as String?,
      members: (tab['members'] as List<dynamic>)
          .map((m) => Member.fromJson(m as Map<String, dynamic>))
          .toList(),
      expenses: (tab['expenses'] as List<dynamic>? ?? [])
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList(),
      settlements: (tab['settlements'] as List<dynamic>? ?? [])
          .map((s) => Settlement.fromJson(s as Map<String, dynamic>))
          .toList(),
      balances: balancesJson.map((k, v) => MapEntry(k, double.parse(v.toString()))),
    );
  }

  double get totalSpent => expenses.fold(0.0, (sum, e) => sum + e.amount);

  /// The member row that belongs to the logged-in user, if any.
  Member? get me {
    final userId = CurrentUser.instance.id;
    if (userId == null) return null;
    for (final m in members) {
      if (m.userId == userId) return m;
    }
    return null;
  }

  String memberName(String id) {
    for (final m in members) {
      if (m.id == id) return m.displayName;
    }
    return '?';
  }
}
