import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class ShareStore extends ChangeNotifier {
  static const _earningsKey = 'earnings_v1';
  static const _rateKey = 'default_rate_v1';
  static const _currencyKey = 'currency_v1';
  static const _corruptBackupKey = 'earnings_corrupt_backup';

  final NumberFormat _nf = NumberFormat('#,##0.00');
  final List<Earning> _earnings = [];
  double _defaultRate = 10.0;
  String _currency = '';
  bool loaded = false;
  int _seq = 0;

  // ------------------------------------------------------------- getters

  List<Earning> get earnings {
    final list = List<Earning>.from(_earnings);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// Every payment across all earnings, newest first, with its earning.
  List<MapEntry<Earning, Payment>> get allPayments {
    final out = <MapEntry<Earning, Payment>>[];
    for (final e in _earnings) {
      for (final p in e.payments) {
        out.add(MapEntry(e, p));
      }
    }
    out.sort((a, b) => b.value.date.compareTo(a.value.date));
    return out;
  }

  double get defaultRate => _defaultRate;
  String get currency => _currency;

  double get totalEarned =>
      round2(_earnings.fold<double>(0, (s, e) => s + e.amount));
  double get totalDue =>
      round2(_earnings.fold<double>(0, (s, e) => s + e.due));
  double get totalPaid =>
      round2(_earnings.fold<double>(0, (s, e) => s + e.paid));
  double get totalRemaining =>
      round2(_earnings.fold<double>(0, (s, e) => s + e.remaining));
  int get partialCount =>
      _earnings.where((e) => e.status == ShareStatus.partial).length;

  String money(double v) =>
      '${_currency.isEmpty ? '' : '$_currency '}${_nf.format(v)}';

  // ------------------------------------------------------------- storage

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _defaultRate = prefs.getDouble(_rateKey) ?? 10.0;
      _currency = prefs.getString(_currencyKey) ?? '';
      final raw = prefs.getString(_earningsKey);
      if (raw != null && raw.isNotEmpty) {
        try {
          final list = jsonDecode(raw) as List;
          _earnings
            ..clear()
            ..addAll(
                list.map((e) => Earning.fromJson(e as Map<String, dynamic>)));
        } catch (_) {
          // Keep the unreadable data under another key instead of losing it.
          await prefs.setString(_corruptBackupKey, raw);
          _earnings.clear();
        }
      }
    } catch (_) {
      // Storage unavailable: start empty rather than crash.
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _earningsKey, jsonEncode(_earnings.map((e) => e.toJson()).toList()));
      await prefs.setDouble(_rateKey, _defaultRate);
      await prefs.setString(_currencyKey, _currency);
    } catch (_) {
      // Ignore write errors; the in-memory state is still correct.
    }
  }

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  Earning? _find(String id) {
    for (final e in _earnings) {
      if (e.id == id) return e;
    }
    return null;
  }

  // ------------------------------------------------------------ earnings

  Future<void> addEarning({
    required DateTime date,
    required double amount,
    required double rate,
    String note = '',
  }) async {
    _earnings.add(Earning(
      id: _newId(),
      date: date,
      amount: amount,
      rate: rate,
      note: note,
    ));
    notifyListeners();
    await _save();
  }

  Future<void> updateEarning(
    String id, {
    required DateTime date,
    required double amount,
    required double rate,
    required String note,
  }) async {
    final e = _find(id);
    if (e == null) return;
    e.date = date;
    e.amount = amount;
    e.rate = rate;
    e.note = note;
    notifyListeners();
    await _save();
  }

  Future<void> deleteEarning(String id) async {
    _earnings.removeWhere((e) => e.id == id);
    notifyListeners();
    await _save();
  }

  // ------------------------------------------------------------ payments

  Future<void> addPayment({
    required String earningId,
    required DateTime date,
    required double amount,
    String note = '',
  }) async {
    final e = _find(earningId);
    if (e == null) return;
    e.payments.add(Payment(
      id: _newId(),
      date: date,
      amount: amount,
      note: note,
    ));
    notifyListeners();
    await _save();
  }

  Future<void> updatePayment(
    String earningId,
    String paymentId, {
    required DateTime date,
    required double amount,
    required String note,
  }) async {
    final e = _find(earningId);
    if (e == null) return;
    for (final p in e.payments) {
      if (p.id == paymentId) {
        p.date = date;
        p.amount = amount;
        p.note = note;
      }
    }
    notifyListeners();
    await _save();
  }

  Future<void> deletePayment(String earningId, String paymentId) async {
    final e = _find(earningId);
    if (e == null) return;
    e.payments.removeWhere((p) => p.id == paymentId);
    notifyListeners();
    await _save();
  }

  // ------------------------------------------------------------ settings

  Future<void> updateSettings({
    required double rate,
    required String currency,
  }) async {
    _defaultRate = rate;
    _currency = currency;
    notifyListeners();
    await _save();
  }

  // -------------------------------------------------------------- export

  String _q(String s) => '"${s.replaceAll('"', '""')}"';

  /// Plain-text CSV of all records, for copying into notes or a spreadsheet.
  String exportCsv() {
    final df = DateFormat('yyyy-MM-dd');
    final b = StringBuffer();
    b.writeln('EARNINGS');
    b.writeln('Date,Earned,Rate %,Share due,Paid,Remaining,Status,Note');
    for (final e in earnings) {
      b.writeln([
        df.format(e.date),
        e.amount.toStringAsFixed(2),
        plainNumber(e.rate),
        e.due.toStringAsFixed(2),
        e.paid.toStringAsFixed(2),
        e.remaining.toStringAsFixed(2),
        e.status.name,
        _q(e.note),
      ].join(','));
    }
    b.writeln();
    b.writeln('CONTRIBUTIONS');
    b.writeln('Payment date,Amount,For month,Note');
    for (final entry in allPayments) {
      b.writeln([
        df.format(entry.value.date),
        entry.value.amount.toStringAsFixed(2),
        DateFormat('yyyy-MM').format(entry.key.date),
        _q(entry.value.note),
      ].join(','));
    }
    return b.toString();
  }
}
