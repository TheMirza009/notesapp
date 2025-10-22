import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:croppy/croppy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notesapp/root/widgets/photo_view/croppy_settings_modal.dart';

/// A result object for [cropImageWithCroppy] calls.
class CroppedImageResult {
  final ui.Image image;
  final CroppableImageData data;
  CroppedImageResult(this.image, this.data);
}

/// A universal cropper launcher that works for Material or Cupertino.
/// Automatically chooses based on [useCupertino] or platform.
Future<CroppedImageResult?> cropImageWithCroppy({
  required BuildContext context,
  required String path,

  /// Optional crop settings (defaults to CropSettings.initial()).
  CropSettings? settings,

  /// Force using Cupertino-style cropper.
  bool? useCupertino,

  /// Optional hero tag (for smooth transition).
  Object? heroTag,
}) async {
  final cropSettings = settings ?? CropSettings.initial();

  // --- Step 1. Create the ImageProvider efficiently ---
  final ImageProvider provider;
  if (path.startsWith('http') || path.startsWith('https')) {
    provider = NetworkImage(path, headers: const {'accept': '*/*'});
  } else if (kIsWeb) {
    provider = NetworkImage(path);
  } else {
    provider = FileImage(File(path));
  }

  // --- Step 2. Initialize CroppableImageData only once (lazy) ---
  final initialData = await CroppableImageData.fromImageProvider(
    provider,
    cropPathFn: cropSettings.cropShapeFn,
  );

  // --- Step 3. Select platform style ---
  final bool useCupertinoCropper =
      useCupertino ?? Theme.of(context).platform == TargetPlatform.iOS;

  final completer = Completer<CroppedImageResult?>();

  Future<void> openCropper() async {
    final showCropper = useCupertinoCropper
        ? showCupertinoImageCropper
        : showMaterialImageCropper;

    final result = await showCropper(
      context,
      locale: cropSettings.locale,
      imageProvider: provider,
      heroTag: heroTag,
      initialData: initialData,
      showGestureHandlesOn: cropSettings.showGestureHandlesOn,
      cropPathFn: cropSettings.cropShapeFn,
      showLoadingIndicatorOnSubmit: false,
      enabledTransformations: cropSettings.enabledTransformations,
      allowedAspectRatios: cropSettings.forcedAspectRatio != null
          ? [cropSettings.forcedAspectRatio!]
          : null,
      postProcessFn: (result) async {
        // Dispose old image and notify caller
        completer.complete(CroppedImageResult(
          result.uiImage,
          result.transformationsData,
        ));
        return result;
      },
    );

    // In case the cropper was dismissed
    if (result == null && !completer.isCompleted) {
      completer.complete(null);
    }
  }

  // --- Step 4. Use microtask to avoid blocking UI ---
  WidgetsBinding.instance.addPostFrameCallback((_) => openCropper());

  return completer.future;
}
