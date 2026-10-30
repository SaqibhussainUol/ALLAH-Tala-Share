import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'models.dart';
import 'store.dart';

const String kAppName = 'ALLAH TALA Share';

final DateFormat _dateFmt = DateFormat('d MMM yyyy');
final DateFormat _monthFmt = DateFormat('MMMM yyyy');

// ------------------------------------------------------------------ theme

class AppColors {
  static const black = Color(0xFF000000);
  static const surface = Color(0xFF111111);
  static const surfaceHigh = Color(0xFF1B1B1B);
  static const gold = Color(0xFFD4AF37);
  static const goldLight = Color(0xFFF3D77A);
  static const goldDim = Color(0xFF9C7F2A);
  static const muted = Color(0xFFB8A66A);
  static const text = Color(0xFFF5ECD0);
  static const line = Color(0x669C7F2A);
  static const paid = Color(0xFF66BB6A);
  static const partial = Color(0xFFFFA726);
  static const unpaid = Color(0xFFEF5350);
}

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.gold,
    onPrimary: Colors.black,
    secondary: AppColors.goldLight,
    onSecondary: Colors.black,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    error: AppColors.unpaid,
    onError: Colors.black,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.black,
    canvasColor: AppColors.black,
  );
  return base.copyWith(
    textTheme: base.textTheme
        .apply(bodyColor: AppColors.text, displayColor: AppColors.text),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.gold,
      foregroundColor: Colors.black,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.black,
        disabledBackgroundColor: const Color(0xFF3A3320),
        disabledForegroundColor: const Color(0xFF7A6D45),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.gold,
        side: const BorderSide(color: AppColors.goldDim),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.gold),
    ),
    iconTheme: const IconThemeData(color: AppColors.gold),
    dividerTheme: const DividerThemeData(color: AppColors.line),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.gold,
      selectionColor: Color(0x55D4AF37),
      selectionHandleColor: AppColors.gold,
    ),
  );
}

InputDecoration goldInput(
  String label, {
  String? error,
  String? prefix,
  String? suffix,
}) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    labelText: label,
    errorText: error,
    prefixText: prefix,
    suffixText: suffix,
    labelStyle: const TextStyle(color: AppColors.muted),
    floatingLabelStyle: const TextStyle(color: AppColors.gold),
    prefixStyle: const TextStyle(color: AppColors.gold),
    suffixStyle: const TextStyle(color: AppColors.gold),
    border: border(AppColors.goldDim),
    enabledBorder: border(AppColors.goldDim),
    focusedBorder: border(AppColors.gold, 2),
    errorBorder: border(AppColors.unpaid),
    focusedErrorBorder: border(AppColors.unpaid, 2),
  );
}

/// Accepts digits with up to 2 decimals; also turns a comma into a dot so
/// keyboards that show "," still work.
final List<TextInputFormatter> decimalFormatters = [
  TextInputFormatter.withFunction(
    (oldValue, newValue) =>
        newValue.copyWith(text: newValue.text.replaceAll(',', '.')),
  ),
  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
];

Color statusColor(ShareStatus s) {
  switch (s) {
    case ShareStatus.paid:
      return AppColors.paid;
    case ShareStatus.partial:
      return AppColors.partial;
    case ShareStatus.unpaid:
      return AppColors.unpaid;
  }
}

String statusLabel(ShareStatus s) {
  switch (s) {
    case ShareStatus.paid:
      return 'Paid in full';
    case ShareStatus.partial:
      return 'Partial';
    case ShareStatus.unpaid:
      return 'Unpaid';
  }
}

Widget goldDialog({
  required String title,
  required Widget content,
  required List<Widget> actions,
}) {
  return AlertDialog(
    backgroundColor: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: AppColors.goldDim),
    ),
    title: Text(
      title,
      style: const TextStyle(
          color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 20),
    ),
    content: SingleChildScrollView(child: content),
    actions: actions,
  );
}

Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  String body = '',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => goldDialog(
      title: title,
      content: body.isEmpty
          ? const SizedBox.shrink()
          : Text(body, style: const TextStyle(color: AppColors.text)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result ?? false;
}

// -------------------------------------------------------------------- app

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const ShareApp());
}

class ShareApp extends StatefulWidget {
  const ShareApp({super.key});

  @override
  State<ShareApp> createState() => _ShareAppState();
}

class _ShareAppState extends State<ShareApp> {
  final ShareStore store = ShareStore();

  @override
  void initState() {
    super.initState();
    store.load();
  }

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      darkTheme: buildTheme(),
      themeMode: ThemeMode.dark,
      home: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          if (!store.loaded) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            );
          }
          return HomeScreen(store: store);
        },
      ),
    );
  }
}

// ----------------------------------------------------------------- screens

class HomeScreen extends StatelessWidget {
  final ShareStore store;
  const HomeScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.gold,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            kAppName,
            style: TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Copy records (CSV)',
              icon: const Icon(Icons.copy_all_outlined, color: AppColors.gold),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: store.exportCsv()));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Records copied. Paste them into Notes or a spreadsheet.'),
                  ),
                );
              },
            ),
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.tune, color: AppColors.gold),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => SettingsDialog(store: store),
              ),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: AppColors.gold,
            indicatorWeight: 3,
            labelColor: AppColors.gold,
            unselectedLabelColor: AppColors.muted,
            tabs: [
              Tab(text: 'Earnings'),
              Tab(text: 'Contributions'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => EarningDialog(store: store),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Add earnings'),
        ),
        body: Column(
          children: [
            _SummaryCard(store: store),
            Expanded(
              child: TabBarView(
                children: [
                  _EarningsList(store: store),
                  _PaymentsList(store: store),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final ShareStore store;
  const _SummaryCard({required this.store});

  Widget _stat(String label, double value, {Color color = AppColors.goldLight}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              store.money(value),
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double progress = store.totalDue <= 0
        ? 0.0
        : (store.totalPaid / store.totalDue).clamp(0.0, 1.0).toDouble();
    final rateText = plainNumber(store.defaultRate);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E2409), Color(0xFF0C0A03)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _stat('Share due', store.totalDue),
              const SizedBox(width: 8),
              _stat('Paid', store.totalPaid, color: AppColors.paid),
              const SizedBox(width: 8),
              _stat('Remaining', store.totalRemaining,
                  color: store.totalRemaining > 0
                      ? AppColors.partial
                      : AppColors.paid),
            ],
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            color: AppColors.gold,
            backgroundColor: const Color(0xFF2A2412),
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 8),
          Text(
            store.partialCount == 0
                ? 'Default rate $rateText% of earnings'
                : '${store.partialCount} month(s) only partly paid · default rate $rateText%',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EarningsList extends StatelessWidget {
  final ShareStore store;
  const _EarningsList({required this.store});

  @override
  Widget build(BuildContext context) {
    final items = store.earnings;
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No earnings yet.\nTap "Add earnings" to enter this month\'s income.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
          12, 4, 12, 96 + MediaQuery.of(context).padding.bottom),
      itemCount: items.length,
      itemBuilder: (context, i) =>
          _EarningTile(store: store, earning: items[i]),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EarningTile extends StatelessWidget {
  final ShareStore store;
  final Earning earning;
  const _EarningTile({required this.store, required this.earning});

  void _edit(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => EarningDialog(store: store, existing: earning),
    );
  }

  void _pay(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => PaymentDialog(store: store, earning: earning),
    );
  }

  Widget _row(String label, double value,
      {bool bold = false, Color? color}) {
    final style = TextStyle(
      color: color ?? AppColors.text,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 8),
          Text(store.money(value), style: style),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = earning;
    final color = statusColor(e.status);
    return Card(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _monthFmt.format(e.date),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StatusPill(label: statusLabel(e.status), color: color),
                PopupMenuButton<String>(
                  color: AppColors.surfaceHigh,
                  icon: const Icon(Icons.more_vert, color: AppColors.gold),
                  onSelected: (v) async {
                    if (v == 'edit') {
                      _edit(context);
                    } else if (v == 'delete') {
                      final ok = await confirmDelete(
                        context,
                        title: 'Delete this entry?',
                        body: 'Its recorded payments will be deleted too.',
                      );
                      if (ok) await store.deleteEarning(e.id);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
                    PopupMenuItem<String>(
                        value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            Text(
              'Received ${_dateFmt.format(e.date)}'
              '${e.note.isEmpty ? '' : ' · ${e.note}'}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            _row('Earned', e.amount),
            _row('$kAppName due (${plainNumber(e.rate)}%)', e.due,
                color: AppColors.goldLight),
            _row('Paid', e.paid, color: AppColors.paid),
            _row('Remaining', e.remaining,
                bold: true,
                color: e.remaining > 0 ? AppColors.partial : AppColors.paid),
            if (e.payments.isNotEmpty) ...[
              const Divider(height: 20),
              for (final p in e.payments)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_dateFmt.format(p.date)}'
                        '${p.note.isEmpty ? '' : ' · ${p.note}'}',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 13),
                      ),
                    ),
                    Text(store.money(p.amount),
                        style: const TextStyle(color: AppColors.text)),
                    IconButton(
                      tooltip: 'Edit payment',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => PaymentDialog(
                            store: store, earning: e, existing: p),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Delete payment',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () async {
                        final ok = await confirmDelete(
                            context, title: 'Delete this payment?');
                        if (ok) await store.deletePayment(e.id, p.id);
                      },
                    ),
                  ],
                ),
            ],
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  onPressed: () => _edit(context),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
                if (e.remaining > 0)
                  FilledButton.icon(
                    onPressed: () => _pay(context),
                    icon: const Icon(Icons.volunteer_activism, size: 18),
                    label: const Text('Pay $kAppName'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentsList extends StatelessWidget {
  final ShareStore store;
  const _PaymentsList({required this.store});

  @override
  Widget build(BuildContext context) {
    final items = store.allPayments;
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No contributions recorded yet.',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.only(
          bottom: 96 + MediaQuery.of(context).padding.bottom),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final e = items[i].key;
        final p = items[i].value;
        return ListTile(
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) =>
                PaymentDialog(store: store, earning: e, existing: p),
          ),
          leading: const Icon(Icons.check_circle_outline, color: AppColors.gold),
          title: Text(
            store.money(p.amount),
            style: const TextStyle(
                color: AppColors.goldLight,
                fontWeight: FontWeight.w700,
                fontSize: 17),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_dateFmt.format(p.date)} · for ${_monthFmt.format(e.date)}',
                style: const TextStyle(color: AppColors.muted),
              ),
              if (p.note.isNotEmpty)
                Text(p.note, style: const TextStyle(color: AppColors.text)),
              if (e.remaining > 0)
                Text(
                  '${store.money(e.remaining)} still due for this month',
                  style: const TextStyle(
                      color: AppColors.partial, fontSize: 12),
                ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            color: AppColors.surfaceHigh,
            icon: const Icon(Icons.more_vert, color: AppColors.gold),
            onSelected: (v) async {
              if (v == 'edit') {
                showDialog<void>(
                  context: context,
                  builder: (_) =>
                      PaymentDialog(store: store, earning: e, existing: p),
                );
              } else if (v == 'delete') {
                final ok = await confirmDelete(context,
                    title: 'Delete this payment?');
                if (ok) await store.deletePayment(e.id, p.id);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
              PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
            ],
          ),
        );
      },
    );
  }
}

// ----------------------------------------------------------------- dialogs

Future<DateTime?> _pickDate(BuildContext context, DateTime initial) {
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );
}

class EarningDialog extends StatefulWidget {
  final ShareStore store;
  final Earning? existing;
  const EarningDialog({super.key, required this.store, this.existing});

  @override
  State<EarningDialog> createState() => _EarningDialogState();
}

class _EarningDialogState extends State<EarningDialog> {
  late final TextEditingController _amount;
  late final TextEditingController _rate;
  late final TextEditingController _note;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _amount = TextEditingController(text: e == null ? '' : plainNumber(e.amount));
    _rate = TextEditingController(
        text: plainNumber(e?.rate ?? widget.store.defaultRate));
    _note = TextEditingController(text: e?.note ?? '');
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amount.dispose();
    _rate.dispose();
    _note.dispose();
    super.dispose();
  }

  double get _amountVal => double.tryParse(_amount.text) ?? 0;
  double get _rateVal => double.tryParse(_rate.text) ?? 0;
  bool get _valid => _amountVal > 0 && _rateVal > 0 && _rateVal <= 100;

  void _save() {
    final store = widget.store;
    final existing = widget.existing;
    if (existing == null) {
      store.addEarning(
        date: _date,
        amount: _amountVal,
        rate: _rateVal,
        note: _note.text.trim(),
      );
    } else {
      store.updateEarning(
        existing.id,
        date: _date,
        amount: _amountVal,
        rate: _rateVal,
        note: _note.text.trim(),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final existing = widget.existing;
    final due = round2(_amountVal * _rateVal / 100);
    final overpaid = existing != null && existing.paid > due + 0.005;
    final rateError = _rate.text.isNotEmpty && (_rateVal <= 0 || _rateVal > 100)
        ? 'Enter a rate between 0.01 and 100'
        : null;

    return goldDialog(
      title: existing == null ? 'Add earnings' : 'Edit earnings',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          TextField(
            controller: _amount,
            autofocus: existing == null,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: decimalFormatters,
            decoration: goldInput(
              'Earnings amount',
              prefix: store.currency.isEmpty ? null : '${store.currency} ',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF241C07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.goldDim),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$kAppName due (${plainNumber(_rateVal)}%)',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    store.money(due),
                    style: const TextStyle(
                      color: AppColors.goldLight,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (overpaid && existing != null) ...[
            const SizedBox(height: 8),
            Text(
              'Already paid ${store.money(existing.paid)}, which is more than the new amount due.',
              style: const TextStyle(color: AppColors.partial, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _rate,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: decimalFormatters,
            decoration: goldInput('Rate for this entry',
                suffix: '%', error: rateError),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(_dateFmt.format(_date)),
            onPressed: () async {
              final d = await _pickDate(context, _date);
              if (d != null) setState(() => _date = d);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            decoration: goldInput('Note (optional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _valid ? _save : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class PaymentDialog extends StatefulWidget {
  final ShareStore store;
  final Earning earning;
  final Payment? existing;
  const PaymentDialog({
    super.key,
    required this.store,
    required this.earning,
    this.existing,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _amount = TextEditingController(
        text: plainNumber(p?.amount ?? widget.earning.remaining));
    _note = TextEditingController(text: p?.note ?? '');
    _date = p?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  double get _amountVal => double.tryParse(_amount.text) ?? 0;

  /// The most this payment can be without exceeding the amount due.
  double get _max {
    final others = widget.earning.paid - (widget.existing?.amount ?? 0);
    final m = round2(widget.earning.due - others);
    return m < 0 ? 0 : m;
  }

  bool get _over => _amountVal > _max + 0.005;
  bool get _valid => _amountVal > 0 && !_over;

  void _save() {
    final store = widget.store;
    final existing = widget.existing;
    if (existing == null) {
      store.addPayment(
        earningId: widget.earning.id,
        date: _date,
        amount: _amountVal,
        note: _note.text.trim(),
      );
    } else {
      store.updatePayment(
        widget.earning.id,
        existing.id,
        date: _date,
        amount: _amountVal,
        note: _note.text.trim(),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final e = widget.earning;
    final left = _max <= _amountVal ? 0.0 : round2(_max - _amountVal);
    final editing = widget.existing != null;

    return goldDialog(
      title: editing ? 'Edit payment' : 'Pay $kAppName',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_monthFmt.format(e.date)} · due ${store.money(e.due)}',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: decimalFormatters,
            decoration: goldInput(
              editing ? 'Payment amount' : 'Amount paying now',
              prefix: store.currency.isEmpty ? null : '${store.currency} ',
              error: _over ? 'More than the amount due (${store.money(_max)})' : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          if (_valid)
            Text(
              left == 0
                  ? 'This pays the month in full.'
                  : 'Partial payment: ${store.money(left)} will remain due.',
              style: TextStyle(
                color: left == 0 ? AppColors.paid : AppColors.partial,
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(_dateFmt.format(_date)),
            onPressed: () async {
              final d = await _pickDate(context, _date);
              if (d != null) setState(() => _date = d);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            decoration: goldInput('Note (optional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _valid ? _save : null,
          child: Text(editing ? 'Save' : 'Record payment'),
        ),
      ],
    );
  }
}

class SettingsDialog extends StatefulWidget {
  final ShareStore store;
  const SettingsDialog({super.key, required this.store});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late final TextEditingController _rate;
  late final TextEditingController _currency;

  @override
  void initState() {
    super.initState();
    _rate = TextEditingController(text: plainNumber(widget.store.defaultRate));
    _currency = TextEditingController(text: widget.store.currency);
  }

  @override
  void dispose() {
    _rate.dispose();
    _currency.dispose();
    super.dispose();
  }

  double get _rateVal => double.tryParse(_rate.text) ?? 0;
  bool get _valid => _rateVal > 0 && _rateVal <= 100;

  @override
  Widget build(BuildContext context) {
    return goldDialog(
      title: 'Settings',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          TextField(
            controller: _rate,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: decimalFormatters,
            decoration: goldInput(
              'Default rate',
              suffix: '%',
              error: _rate.text.isNotEmpty && !_valid
                  ? 'Enter a rate between 0.01 and 100'
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 6),
          const Text(
            'Used for new entries. Existing entries keep their own rate; change one with Edit.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _currency,
            maxLength: 6,
            decoration: goldInput('Currency symbol (optional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _valid
              ? () {
                  widget.store.updateSettings(
                    rate: _rateVal,
                    currency: _currency.text.trim(),
                  );
                  Navigator.pop(context);
                }
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
