import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/fee_type.dart';
import '../models/payment.dart';
import '../theme.dart';
import '../utils/formatters.dart';

/// Bảng nhập số tiền cho một khoản phí.
class FeeEditorSheet extends StatefulWidget {
  final Payment payment;

  const FeeEditorSheet({super.key, required this.payment});

  static Future<bool?> show(BuildContext context, Payment payment) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FeeEditorSheet(payment: payment),
    );
  }

  @override
  State<FeeEditorSheet> createState() => _FeeEditorSheetState();
}

class _FeeEditorSheetState extends State<FeeEditorSheet> {
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late final TextEditingController _meterOld;
  late final TextEditingController _meterNew;
  late final TextEditingController _unitPrice;
  final Map<String, TextEditingController> _breakdown = {};

  bool _useMeter = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.payment;

    _amount = TextEditingController(
      text: p.amount > 0 ? formatMoney(p.amount, withSymbol: false) : '',
    );
    _note = TextEditingController(text: p.note ?? '');
    _meterOld = TextEditingController(
        text: p.meterOld == null ? '' : _trimNum(p.meterOld!));
    _meterNew = TextEditingController(
        text: p.meterNew == null ? '' : _trimNum(p.meterNew!));
    _unitPrice = TextEditingController(
      text: p.unitPrice != null
          ? formatMoney(p.unitPrice!, withSymbol: false)
          : '',
    );
    _useMeter = p.meterOld != null && p.meterNew != null;

    for (final item in kManagementItems) {
      final value = p.breakdown[item.key] ?? 0;
      _breakdown[item.key] = TextEditingController(
        text: value > 0 ? formatMoney(value, withSymbol: false) : '',
      );
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _meterOld.dispose();
    _meterNew.dispose();
    _unitPrice.dispose();
    for (final c in _breakdown.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _trimNum(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  double get _meterAmount {
    final old = double.tryParse(_meterOld.text.replaceAll(',', '.')) ?? 0;
    final now = double.tryParse(_meterNew.text.replaceAll(',', '.')) ?? 0;
    final price = parseMoney(_unitPrice.text);
    final used = now - old;
    if (used <= 0 || price <= 0) return 0;
    return used * price;
  }

  double get _breakdownTotal => _breakdown.values
      .fold<double>(0, (sum, c) => sum + parseMoney(c.text));

  double get _finalAmount {
    if (widget.payment.type == FeeType.management) {
      final sum = _breakdownTotal;
      return sum > 0 ? sum : parseMoney(_amount.text);
    }
    if (widget.payment.type == FeeType.electricity && _useMeter) {
      final m = _meterAmount;
      return m > 0 ? m : parseMoney(_amount.text);
    }
    return parseMoney(_amount.text);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final state = context.read<AppState>();
    final p = widget.payment;

    final breakdownMap = <String, double>{};
    if (p.type == FeeType.management) {
      for (final item in kManagementItems) {
        final v = parseMoney(_breakdown[item.key]!.text);
        if (v > 0) breakdownMap[item.key] = v;
      }
    }

    final updated = p.copyWith(
      amount: _finalAmount,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      clearNote: _note.text.trim().isEmpty,
      breakdown: breakdownMap,
      meterOld: _useMeter
          ? double.tryParse(_meterOld.text.replaceAll(',', '.'))
          : null,
      meterNew: _useMeter
          ? double.tryParse(_meterNew.text.replaceAll(',', '.'))
          : null,
      unitPrice: _useMeter ? parseMoney(_unitPrice.text) : null,
      clearMeter: !_useMeter,
    );

    await state.savePayment(updated);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payment;
    final color = FeeColors.of(context, p.type);
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppTheme.borderOf(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: tintScaffold(context, color, 0.16),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(p.type.icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.type.label,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(formatMonthLabel(p.year, p.month),
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (p.type == FeeType.electricity) _electricitySection(color),
            if (p.type == FeeType.management) _managementSection(),
            if (p.type == FeeType.room) _roomSection(),

            const SizedBox(height: 16),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (nội dung chuyển khoản, thoả thuận...)',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 20),
            _TotalRow(amount: _finalAmount, color: color),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined, size: 19),
              label: Text(_saving ? 'Đang lưu...' : 'Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------- tiền điện

  Widget _electricitySection(Color color) {
    final state = context.read<AppState>();
    final used = (double.tryParse(_meterNew.text.replaceAll(',', '.')) ?? 0) -
        (double.tryParse(_meterOld.text.replaceAll(',', '.')) ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile.adaptive(
          value: _useMeter,
          contentPadding: EdgeInsets.zero,
          title: const Text('Tính theo chỉ số công tơ'),
          subtitle: const Text('Nhập số cũ, số mới và đơn giá'),
          onChanged: (v) {
            setState(() {
              _useMeter = v;
              if (v && _unitPrice.text.isEmpty && state.defaultUnitPrice > 0) {
                _unitPrice.text =
                    formatMoney(state.defaultUnitPrice, withSymbol: false);
              }
            });
          },
        ),
        const SizedBox(height: 8),
        if (_useMeter) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _meterOld,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Số cũ'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _meterNew,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Số mới'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _unitPrice,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsFormatter()],
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Đơn giá 1 kWh',
              suffixText: '₫',
            ),
          ),
          if (used > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tintScaffold(context, color, 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calculate_outlined, size: 18, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dùng ${_trimNum(used)} kWh → ${formatMoney(_meterAmount)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ] else
          _amountField('Số tiền điện'),
      ],
    );
  }

  // ---------------------------------------------------------- tiền quản lý

  Widget _managementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chi tiết các khoản',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        for (final item in kManagementItems) ...[
          TextField(
            controller: _breakdown[item.key],
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsFormatter()],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: item.label,
              prefixIcon: Icon(item.icon, size: 20),
              suffixText: '₫',
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  // ---------------------------------------------------------- tiền phòng

  Widget _roomSection() {
    final state = context.read<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _amountField('Tiền phòng tháng này'),
        if (state.defaultRoom > 0) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              avatar: const Icon(Icons.bolt_outlined, size: 17),
              label: Text('Dùng mức mặc định ${formatMoney(state.defaultRoom)}'),
              onPressed: () {
                setState(() {
                  _amount.text =
                      formatMoney(state.defaultRoom, withSymbol: false);
                });
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _amountField(String label) {
    return TextField(
      controller: _amount,
      keyboardType: TextInputType.number,
      inputFormatters: [ThousandsFormatter()],
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        suffixText: '₫',
        prefixIcon: const Icon(Icons.payments_outlined),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final double amount;
  final Color color;

  const _TotalRow({required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tintScaffold(context, color, 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tintScaffold(context, color, 0.35)),
      ),
      child: Row(
        children: [
          const Text('Thành tiền',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const Spacer(),
          Text(
            formatMoney(amount),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
