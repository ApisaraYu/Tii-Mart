import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../../app/theme/app_theme.dart';

/// ส่วนเลือกรูปสินค้าหลายรูป: รูปเดิม (URL) + รูปใหม่ที่เพิ่งเลือก (ยังไม่อัพโหลด)
class ImagePickerSection extends StatelessWidget {
  const ImagePickerSection({
    super.key,
    required this.existingUrls,
    required this.newImages,
    required this.onAdd,
    required this.onRemoveExisting,
    required this.onRemoveNew,
    required this.maxImages,
    this.enabled = true,
  });

  final List<String> existingUrls;
  final List<Uint8List> newImages;
  final VoidCallback onAdd;
  final void Function(int index) onRemoveExisting;
  final void Function(int index) onRemoveNew;
  final int maxImages;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final total = existingUrls.length + newImages.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < existingUrls.length; i++)
              _ImageTile(
                isMain: i == 0,
                onRemove: enabled ? () => onRemoveExisting(i) : null,
                child: Image.network(
                  existingUrls[i],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image_outlined),
                ),
              ),
            for (var i = 0; i < newImages.length; i++)
              _ImageTile(
                isMain: existingUrls.isEmpty && i == 0,
                onRemove: enabled ? () => onRemoveNew(i) : null,
                child: Image.memory(newImages[i], fit: BoxFit.cover),
              ),
            if (total < maxImages)
              InkWell(
                onTap: enabled ? onAdd : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          color: AppColors.primary),
                      SizedBox(height: 4),
                      Text('เพิ่มรูป', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '$total / $maxImages รูป  (รูปแรกคือรูปหลักที่แสดงในรายการ)',
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.child,
    required this.isMain,
    required this.onRemove,
  });

  final Widget child;
  final bool isMain;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: child),
          if (isMain)
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'รูปหลัก',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
          if (onRemove != null)
            Positioned(
              top: 2,
              right: 2,
              child: InkWell(
                onTap: onRemove,
                child: const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
