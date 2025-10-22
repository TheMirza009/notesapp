import 'dart:io';
import 'dart:math';
import 'package:croppy/croppy.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:notesapp/root/widgets/photo_view/croppy_custom_cropper.dart';
import 'dart:ui' as ui;

import 'package:notesapp/root/widgets/photo_view/croppy_settings_modal.dart';


class CroppyExample extends StatefulWidget {
  const CroppyExample({super.key});

  @override
  State<CroppyExample> createState() => _CroppyExampleState();
}

class _CroppyExampleState extends State<CroppyExample> {
  late final PageController _pageController;
  var _cropSettings = CropSettings.initial();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.9,
    );

    final random = Random();
    for (var i = 0; i < 80; i++) {
      final image = NetworkImage(
        'https://test-photos-qklwjen.s3.eu-west-3.amazonaws.com/image${random.nextInt(80) + 1}.jpg',
        headers: const {'accept': '*/*'},
      );

      _imageProviders.add(image);
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final path = result.files.first.path!;

      if (kIsWeb) {
        _imageProviders.insert(0, NetworkImage(path));
      } else {
        _imageProviders.insert(0, FileImage(File(path)));
      }

      setState(() {});
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final _imageProviders = <ImageProvider>[];
  final _data = <int, CroppableImageData>{};
  final _croppedImage = <int, ui.Image>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () async {
              final newSettings = await showCropSettingsModal(
                context: context,
                initialSettings: _cropSettings,
              );

              setState(() {
                _cropSettings = newSettings;
              });
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: _pickImage,
            label: const Text('Pick image'),
          ),
          const SizedBox(width: 16.0),
          FloatingActionButton(
            onPressed: () {
              final page = _pageController.page?.round() ?? 0;

              showCupertinoImageCropper(
                context,
                locale: _cropSettings.locale,
                imageProvider: _imageProviders[page],
                heroTag: 'image-$page',
                initialData: _data[page],
                showGestureHandlesOn: _cropSettings.showGestureHandlesOn,
                cropPathFn: _cropSettings.cropShapeFn,
                showLoadingIndicatorOnSubmit: false,
                enabledTransformations: _cropSettings.enabledTransformations,
                allowedAspectRatios: _cropSettings.forcedAspectRatio != null
                    ? [_cropSettings.forcedAspectRatio!]
                    : null,
                postProcessFn: (result) async {
                  _croppedImage[page]?.dispose();

                  setState(() {
                    _croppedImage[page] = result.uiImage;
                    _data[page] = result.transformationsData;
                  });

                  return result;
                },
              );
            },
            heroTag: 'fab-cupertino',
            child: const Icon(Icons.apple_rounded),
          ),
          const SizedBox(width: 16.0),
          FloatingActionButton(
            onPressed: () {
              final page = _pageController.page?.round() ?? 0;

              showMaterialImageCropper(
                context,
                locale: _cropSettings.locale,
                imageProvider: _imageProviders[page],
                heroTag: 'image-$page',
                initialData: _data[page],
                cropPathFn: _cropSettings.cropShapeFn,
                enabledTransformations: _cropSettings.enabledTransformations,
                allowedAspectRatios: _cropSettings.forcedAspectRatio != null
                    ? [_cropSettings.forcedAspectRatio!]
                    : null,
                showLoadingIndicatorOnSubmit: false,
                postProcessFn: (result) async {
                  _croppedImage[page]?.dispose();

                  setState(() {
                    _croppedImage[page] = result.uiImage;
                    _data[page] = result.transformationsData;
                  });

                  return result;
                },
              );
            },
            heroTag: 'fab-material',
            child: const Icon(Icons.android_rounded),
          ),
          const SizedBox(width: 16.0),
          FloatingActionButton(
            onPressed: () {
              final page = _pageController.page?.round() ?? 0;

              showCustomCropper(
                context,
                _imageProviders[page],
                heroTag: 'image-$page',
                initialData: _data[page],
                onCropped: (result) async {
                  _croppedImage[page]?.dispose();

                  setState(() {
                    _croppedImage[page] = result.uiImage;
                    _data[page] = result.transformationsData;
                  });

                  return result;
                },
              );
            },
            heroTag: 'fab-custom',
            child: const Icon(Icons.edit_rounded),
          ),
        ],
      ),
      body: Center(
        child: PageView.builder(
          controller: _pageController,
          itemCount: _imageProviders.length,
          scrollDirection: Axis.horizontal,
          padEnds: true,
          itemBuilder: (context, i) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Hero(
                  tag: 'image-$i',
                  placeholderBuilder: (context, size, child) =>
                      Visibility.maintain(
                    visible: false,
                    child: child,
                  ),
                  child: _croppedImage[i] != null
                      ? RawImage(image: _croppedImage[i])
                      : Image(image: _imageProviders[i]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}