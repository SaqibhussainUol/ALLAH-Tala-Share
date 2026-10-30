/// Rounds to 2 decimal places to avoid floating point noise (0.1 + 0.2 etc).
double round2(double v) => (v * 100).roundToDouble() / 100;

/// 1500.00 -> "1500", 12.50 -> "12.5". Used to prefill text fields.
String plainNumber(double v) {
  var s = v.toStringAsFixed(2);
  if (s.contains('.')) {
    s = s.replaceAll(RegExp(r'0+$'), '');
    s = s.replaceAll(RegExp(r'\.$'), '');
  }
  return s;
}

class Payment {
  final String id;
  DateTime date;
  double amount;
  String note;

  Payment({
    required this.id,
    required this.date,
    required this.amount,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'amount': amount,
        'note': note,
      };

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        amount: (j['amount'] as num).toDouble(),
        note: (j['note'] as String?) ?? '',
      );
}

enum ShareStatus { unpaid, partial, paid }

class Earning {
  final String id;
  DateTime date;
  double amount;

  /// Rate in percent. Stored per entry so changing the default rate later
  /// does not alter past records (each entry can also be edited on its own).
  double rate;
  String note;
  final List<Payment> payments;

  Earning({
    required this.id,
    required this.date,
    required this.amount,
    required this.rate,
    this.note = '',
    List<Payment>? payments,
  }) : payments = payments ?? [];

  double get due => round2(amount * rate / 100);

  double get paid =>
      round2(payments.fold<double>(0, (sum, p) => sum + p.amount));

  double get remaining {
    final r = round2(due - paid);
    return r < 0 ? 0 : r;
  }

  ShareStatus get status {
    if (due > 0 && remaining == 0) return ShareStatus.paid;
    if (paid > 0) return ShareStatus.partial;
    return ShareStatus.unpaid;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'amount': amount,
        'rate': rate,
        'note': note,
        'payments': payments.map((p) => p.toJson()).toList(),
      };

  factory Earning.fromJson(Map<String, dynamic> j) => Earning(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        amount: (j['amount'] as num).toDouble(),
        rate: (j['rate'] as num).toDouble(),
        note: (j['note'] as String?) ?? '',
        payments: ((j['payments'] as List?) ?? [])
            .map((p) => Payment.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}
