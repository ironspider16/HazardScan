import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:kkhazardscan/Design/style_constant.dart';

import 'Menu_button.dart';

class AppImageUpload extends StatefulWidget {
  final Function(Uint8List) onImageSelected;
  final String label;

  const AppImageUpload({
    super.key,
    required this.onImageSelected,
    this.label = "Take Photo",
  });

  @override
  State<AppImageUpload> createState() => _AppImageUploadState();
}

class _AppImageUploadState extends State<AppImageUpload> {
  Uint8List? _imageBytes; // Store bytes instead of File

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    final bytes = await photo.readAsBytes(); // Works on Web, iOS, Android
    setState(() => _imageBytes = bytes);
    widget.onImageSelected(bytes);
  }

  @override
Widget build(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: AppPadding.tight),
      const Text(
        'Attachments required',
        style: AppTypography.Blacksubheading,
      ),
      const SizedBox(height: AppPadding.medium),
      if (_imageBytes != null) 
        Padding(
          padding: const EdgeInsets.only(bottom: AppPadding.medium),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            child: Image.memory(
              _imageBytes!, 
              height: 200, 
              width: double.infinity, 
              fit: BoxFit.cover
            ),
          ),
        ),
      MenuButton(label: "Take Photo", onTap: _pickImage, isPrimary: true),
    ],
  );
}
}
