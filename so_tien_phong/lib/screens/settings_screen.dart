import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import '../utils/formatters.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _Section(
            title: 'Giao diện',
            child: Column(
              children: [
                _ThemeOption(
                  label: 'Theo hệ thống',
                  icon: Icons.brightness_auto,
                  selected: state.themeMode == ThemeMode.system,
                  onTap: () => state.setThemeMode(ThemeMode.system),
                ),
                _ThemeOption(
                  label: 'Sáng',
                  icon: Icons.light_mode_outlined,
                  selected: state.themeMode == ThemeMode.light,
                  onTap: () => state.setThemeMode(ThemeMode.light),
                ),
                _ThemeOption(
                  label: 'Tối',
                  icon: Icons.dark_mode_outlined,
                  selected: state.themeMode == ThemeMode.dark,
                  onTap: () => state.setThemeMode(ThemeMode.dark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ReminderSection(state: state),
          const SizedBox(height: 14),
          _DefaultsSection(state: state),
          const SizedBox(height: 14),
          _Section(
            title: 'Dữ liệu',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Toàn bộ dữ liệu nằm trên máy bạn. Gỡ ứng dụng sẽ mất dữ liệu.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _confirmClear(context, state),
                  icon: Icon(Icons.delete_outline,
                      size: 19, color: StatusColors.bad(context)),
                  label: Text(
                    'Xoá toàn bộ dữ liệu',
                    style: TextStyle(color: StatusColors.bad(context)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Giới thiệu',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sổ tiền phòng — phiên bản 1.0.0',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  'Ghi nhớ tiền điện, tiền phòng và phí quản lý mỗi tháng: '
                  'đã đóng hay chưa, đóng lúc nào, bằng hình thức gì.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, AppState state) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá toàn bộ dữ liệu?'),
        content: const Text(
          'Tất cả các tháng, hoá đơn và ảnh sẽ bị xoá vĩnh viễn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá hết'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await state.clearAllData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xoá toàn bộ dữ liệu.')),
        );
      }
    }
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        selected ? theme.colorScheme.primary : theme.colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: selected ? theme.colorScheme.primary : theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- nhắc nhở

class _ReminderSection extends StatelessWidget {
  final AppState state;

  const _ReminderSection({required this.state});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Nhắc đóng tiền hàng tháng',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            value: state.reminderEnabled,
            contentPadding: EdgeInsets.zero,
            title: const Text('Bật nhắc nhở'),
            subtitle: Text(
              state.reminderEnabled
                  ? 'Nhắc ngày ${state.reminderDay} hàng tháng, '
                      'lúc ${state.reminderTime.format(context)}'
                  : 'Ứng dụng sẽ nhắc bạn kiểm tra 3 khoản phí',
            ),
            onChanged: (v) async {
              final ok = await state.setReminder(enabled: v);
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Chưa được cấp quyền thông báo. Hãy bật trong Cài đặt hệ thống.'),
                  ),
                );
              }
            },
          ),
          if (state.reminderEnabled) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _MiniPicker(
                    icon: Icons.today_outlined,
                    label: 'Ngày trong tháng',
                    value: 'Ngày ${state.reminderDay}',
                    onTap: () => _pickDay(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniPicker(
                    icon: Icons.schedule_outlined,
                    label: 'Giờ nhắc',
                    value: state.reminderTime.format(context),
                    onTap: () => _pickTime(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => NotificationService.instance.showTest(),
              icon: const Icon(Icons.notifications_active_outlined, size: 18),
              label: const Text('Gửi thử một thông báo'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickDay(BuildContext context) async {
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Nhắc vào ngày'),
        children: [
          SizedBox(
            width: 300,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: List.generate(28, (i) {
                final d = i + 1;
                return SizedBox(
                  width: 44,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, d),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(44, 40),
                    ),
                    child: Text('$d'),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
    if (picked != null) {
      await state.setReminder(enabled: true, day: picked);
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: state.reminderTime,
      helpText: 'Chọn giờ nhắc',
    );
    if (picked != null) {
      await state.setReminder(enabled: true, time: picked);
    }
  }
}

class _MiniPicker extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _MiniPicker({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderOf(context)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  Text(value,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- mặc định

class _DefaultsSection extends StatefulWidget {
  final AppState state;

  const _DefaultsSection({required this.state});

  @override
  State<_DefaultsSection> createState() => _DefaultsSectionState();
}

class _DefaultsSectionState extends State<_DefaultsSection> {
  late final TextEditingController _room;
  late final TextEditingController _management;
  late final TextEditingController _unitPrice;

  @override
  void initState() {
    super.initState();
    _room = TextEditingController(
      text: widget.state.defaultRoom > 0
          ? formatMoney(widget.state.defaultRoom, withSymbol: false)
          : '',
    );
    _management = TextEditingController(
      text: widget.state.defaultManagement > 0
          ? formatMoney(widget.state.defaultManagement, withSymbol: false)
          : '',
    );
    _unitPrice = TextEditingController(
      text: widget.state.defaultUnitPrice > 0
          ? formatMoney(widget.state.defaultUnitPrice, withSymbol: false)
          : '',
    );
  }

  @override
  void dispose() {
    _room.dispose();
    _management.dispose();
    _unitPrice.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await widget.state.setDefaults(
      room: parseMoney(_room.text),
      management: parseMoney(_management.text),
      unitPrice: parseMoney(_unitPrice.text),
    );
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu mức mặc định.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Mức mặc định',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Điền sẵn để nhập nhanh mỗi tháng.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _room,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsFormatter()],
            decoration: const InputDecoration(
              labelText: 'Tiền phòng hàng tháng',
              suffixText: '₫',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _management,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsFormatter()],
            decoration: const InputDecoration(
              labelText: 'Tiền quản lý hàng tháng',
              suffixText: '₫',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _unitPrice,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsFormatter()],
            decoration: const InputDecoration(
              labelText: 'Đơn giá điện (1 kWh)',
              suffixText: '₫',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Lưu mức mặc định'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- khung

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
