import 'dart:io';

import 'package:flutter/material.dart';

/// Xem ảnh hoá đơn toàn màn hình, vuốt để chuyển ảnh, kéo để phóng to.
class PhotoViewerScreen extends StatefulWidget {
  final List<String> paths;
  final int initialIndex;
  final String title;

  const PhotoViewerScreen({
    super.key,
    required this.paths,
    this.initialIndex = 0,
    this.title = 'Ảnh hoá đơn',
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${widget.title} • ${_index + 1}/${widget.paths.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.paths.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) {
          return InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: Center(
              child: Image.file(
                File(widget.paths[i]),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_outlined,
                      size: 60, color: Colors.white54),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
