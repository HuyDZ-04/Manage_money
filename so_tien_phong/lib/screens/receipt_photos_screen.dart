import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/fee_type.dart';
import '../services/image_service.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import 'photo_viewer_screen.dart';

/// Quản lý ảnh hoá đơn người dùng tự chụp / tự thêm.
class ReceiptPhotosScreen extends StatefulWidget {
  final int year;
  final int month;
  final FeeType type;

  const ReceiptPhotosScreen({
    super.key,
    required this.year,
    required this.month,
    required this.type,
  });

  @override
  State<ReceiptPhotosScreen> createState() => _ReceiptPhotosScreenState();
}

class _ReceiptPhotosScreenState extends State<ReceiptPhotosScreen> {
  late FeeType _type;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _type = widget.type;
  }

  Future<void> _add(ImageSource source) async {
    setState(() => _busy = true);
    try {
      final state = context.read<AppState>();
      final payment = state.paymentOf(widget.year, widget.month, _type);

      List<String> paths;
      if (source == ImageSource.gallery) {
        paths = await ImageService.instance.pickMultiple();
      } else {
        final one = await ImageService.instance.pick(source);
        paths = one == null ? [] : [one];
      }
      if (paths.isEmpty) return;
      await state.addImages(payment, paths);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thêm được ảnh: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(String path) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá ảnh này?'),
        content: const Text('Ảnh sẽ bị xoá khỏi ứng dụng.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final state = context.read<AppState>();
    final payment = state.paymentOf(widget.year, widget.month, _type);
    await state.removeImage(payment, path);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final payment = state.paymentOf(widget.year, widget.month, _type);
    final images = payment.images;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ảnh hoá đơn'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                for (final t in FeeType.values) ...[
                  Expanded(
                    child: _TypeTab(
                      type: t,
                      selected: t == _type,
                      count: state
                          .paymentOf(widget.year, widget.month, t)
                          .images
                          .length,
                      onTap: () => setState(() => _type = t),
                    ),
                  ),
                  if (t != FeeType.values.last) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Icon(Icons.calendar_month_outlined,
                    size: 15,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  '${_type.label} • ${formatMonthLabel(widget.year, widget.month)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: images.isEmpty
                ? _EmptyState(busy: _busy, onAdd: _add)
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: images.length,
                    itemBuilder: (context, i) {
                      final path = images[i];
                      return _PhotoTile(
                        path: path,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PhotoViewerScreen(
                              paths: images,
                              initialIndex: i,
                              title: _type.label,
                            ),
                          ),
                        ),
                        onDelete: () => _delete(path),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _busy
          ? const FloatingActionButton(
              onPressed: null,
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          : FloatingActionButton.extended(
              onPressed: () => _showSourceSheet(),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Thêm ảnh'),
            ),
    );
  }

  void _showSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Chụp ảnh hoá đơn'),
              onTap: () {
                Navigator.pop(ctx);
                _add(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(ctx);
                _add(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  final FeeType type;
  final bool selected;
  final int count;
  final VoidCallback onTap;

  const _TypeTab({
    required this.type,
    required this.selected,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = FeeColors.of(context, type);
    final base = Theme.of(context).scaffoldBackgroundColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? blend(base, color, 0.16) : base,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? blend(base, color, 0.5)
                : AppTheme.borderOf(context),
          ),
        ),
        child: Column(
          children: [
            Icon(type.icon,
                size: 17,
                color: selected
                    ? color
                    : Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 3),
            Text(
              count > 0 ? '${type.label} ($count)' : type.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected
                    ? color
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String path;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PhotoTile({
    required this.path,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppTheme.borderOf(context),
                child: const Center(
                  child: Icon(Icons.broken_image_outlined, size: 32),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: Material(
            color: const Color(0xCC1A1A19),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onDelete,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool busy;
  final Future<void> Function(ImageSource) onAdd;

  const _EmptyState({required this.busy, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 52, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 14),
            Text(
              'Chưa có ảnh nào',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Chụp lại biên lai hoặc màn hình chuyển khoản để đối chiếu sau này.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: busy ? null : () => onAdd(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: const Text('Chụp'),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: busy ? null : () => onAdd(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Thư viện'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
