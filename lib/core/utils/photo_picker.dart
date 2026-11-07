import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_constants.dart';
import '../widgets/state_views.dart';

/// Asks "Camera or Gallery?", then returns the chosen photo's bytes.
///
/// Returns null if the user cancels. The image is resized and compressed on
/// the device (max 1600px, 80% JPEG quality) so uploads are fast and stay
/// well under the 5 MB limit.
Future<Uint8List?> pickPhoto(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (source == null) return null;

  try {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 80,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    if (bytes.lengthInBytes > AppConstants.maxPhotoBytes) {
      if (context.mounted) {
        context.showError('That photo is too large. Please choose another.');
      }
      return null;
    }
    return bytes;
  } on PlatformException catch (e) {
    // Usually the user denied camera / photo permission.
    if (context.mounted) {
      context.showError(
        e.code.contains('denied')
            ? 'Permission denied. Allow camera/photo access in Settings.'
            : 'Could not open the ${source.name}.',
      );
    }
    return null;
  }
}
