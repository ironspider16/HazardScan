import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import '../Design/style_constant.dart';
import 'Menu_button.dart';

class AppImageUpload extends StatefulWidget {
  final Function(File) onImageSelected;
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
  File? _selectedImage;
  bool _isCompressing = false;

  Future<void> _pickAndCompress() async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo == null) {
      setState(() => _isCompressing = false);
      return;
    }

    setState(() => _isCompressing = true);

    final dir = await path_provider.getTemporaryDirectory();
    final targetPath =
        "${dir.absolute.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg";

    final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
      photo.path,
      targetPath,
      quality: 70, // 70-80 is the sweet spot for quality vs size
      minWidth: 1024,
      minHeight: 1024,
    );

    if (compressedFile != null) {
      final file = File(compressedFile.path);
      setState(() {
        _selectedImage = file;
        _isCompressing = false;
      });
      widget.onImageSelected(file);
    }
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
        if (_selectedImage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppPadding.medium),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              child: Image.file(
                _selectedImage!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),

        MenuButton(
          label: _isCompressing ? "Compressing..." : "Submit Image",
          onTap: _isCompressing ? () => {} : _pickAndCompress,
          isPrimary: true,
          icon: _isCompressing ? null : Icons.camera_alt_outlined,
        ),
      ],
    );
  }
}
