// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import 'src/messages.g.dart';

// Converts an [ImageSource] to the corresponding Pigeon API enum value.
SourceType_V2 _convertSource(ImageSource source) {
  switch (source) {
    case ImageSource.camera:
      return SourceType_V2.camera;
    case ImageSource.gallery:
      return SourceType_V2.gallery;
  }
  // The enum comes from a different package, which could get a new value at
  // any time, so a fallback case is necessary. Since there is no reasonable
  // default behavior, throw to alert the client that they need an updated
  // version. This is deliberately outside the switch rather than a `default`
  // so that the linter will flag the switch as needing an update.
  // ignore: dead_code
  throw UnimplementedError('Unknown source: $source');
}

// Converts a [CameraDevice] to the corresponding Pigeon API enum value.
SourceCamera_V2 _convertCamera(CameraDevice camera) {
  switch (camera) {
    case CameraDevice.front:
      return SourceCamera_V2.front;
    case CameraDevice.rear:
      return SourceCamera_V2.rear;
  }
  // The enum comes from a different package, which could get a new value at
  // any time, so a fallback case is necessary. Since there is no reasonable
  // default behavior, throw to alert the client that they need an updated
  // version. This is deliberately outside the switch rather than a `default`
  // so that the linter will flag the switch as needing an update.
  // ignore: dead_code
  throw UnimplementedError('Unknown camera: $camera');
}

/// An implementation of [ImagePickerPlatform] for iOS.
class ImagePickerIOSChatV2 extends ImagePickerPlatform {
  /// Creates a new plugin implementation instance.
  ImagePickerIOSChatV2({@visibleForTesting ImagePickerApi_V2? api})
    : _hostApi = api ?? ImagePickerApi_V2();

  final ImagePickerApi_V2 _hostApi;

  /// Registers this class as the default platform implementation.
  static void registerWith() {
    ImagePickerPlatform.instance = ImagePickerIOSChatV2();
  }

  @override
  Future<PickedFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    final String? path = await _pickImageAsPath(
      source: source,
      options: ImagePickerOptions(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        preferredCameraDevice: preferredCameraDevice,
      ),
    );
    return path != null ? PickedFile(path) : null;
  }

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    final String? path = await _pickImageAsPath(
      source: source,
      options: options,
    );
    return path != null ? XFile(path) : null;
  }

  @override
  Future<List<PickedFile>?> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    final List<String> paths = await _pickMultiImageAsPath(
      options: MultiImagePickerOptions(
        imageOptions: ImageOptions(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: imageQuality,
        ),
      ),
    );
    // Convert an empty list to a null return since that was the legacy behavior
    // of this method.
    if (paths.isEmpty) {
      return null;
    }

    return paths.map((String path) => PickedFile(path)).toList();
  }

  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async {
    final List<String> paths = await _pickMultiImageAsPath(options: options);
    return paths.map((String path) => XFile(path)).toList();
  }

  Future<List<String>> _pickMultiImageAsPath({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async {
    final int? imageQuality = options.imageOptions.imageQuality;
    if (imageQuality != null && (imageQuality < 0 || imageQuality > 100)) {
      throw ArgumentError.value(
        imageQuality,
        'imageQuality',
        'must be between 0 and 100',
      );
    }

    final double? maxWidth = options.imageOptions.maxWidth;
    if (maxWidth != null && maxWidth < 0) {
      throw ArgumentError.value(maxWidth, 'maxWidth', 'cannot be negative');
    }

    final double? maxHeight = options.imageOptions.maxHeight;
    if (maxHeight != null && maxHeight < 0) {
      throw ArgumentError.value(maxHeight, 'maxHeight', 'cannot be negative');
    }

    final int? limit = options.limit;
    if (limit != null && limit < 2) {
      throw ArgumentError.value(limit, 'limit', 'cannot be lower than 2');
    }

    return _hostApi.pickMultiImage(
      MaxSize_V2(width: maxWidth, height: maxHeight),
      imageQuality,
      options.imageOptions.requestFullMetadata,
      limit,
    );
  }

  Future<String?> _pickImageAsPath({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) {
    final int? imageQuality = options.imageQuality;
    if (imageQuality != null && (imageQuality < 0 || imageQuality > 100)) {
      throw ArgumentError.value(
        imageQuality,
        'imageQuality',
        'must be between 0 and 100',
      );
    }

    final double? maxHeight = options.maxHeight;
    final double? maxWidth = options.maxWidth;
    if (maxWidth != null && maxWidth < 0) {
      throw ArgumentError.value(maxWidth, 'maxWidth', 'cannot be negative');
    }

    if (maxHeight != null && maxHeight < 0) {
      throw ArgumentError.value(maxHeight, 'maxHeight', 'cannot be negative');
    }

    return _hostApi.pickImage(
      SourceSpecification_V2(
        type: _convertSource(source),
        camera: _convertCamera(options.preferredCameraDevice),
      ),
      MaxSize_V2(width: maxWidth, height: maxHeight),
      imageQuality,
      options.requestFullMetadata,
    );
  }

  @override
  Future<List<XFile>> getMedia({required MediaOptions options}) async {
    final MediaSelectionOptions_V2 mediaSelectionOptions =
        _mediaOptionsToMediaSelectionOptions_V2(options);

    return (await _hostApi.pickMedia(
      mediaSelectionOptions,
    )).map((String? path) => XFile(path!)).toList();
  }

  MaxSize_V2 _imageOptionsToMaxSize_V2WithValidation(
    ImageOptions imageOptions,
  ) {
    final double? maxHeight = imageOptions.maxHeight;
    final double? maxWidth = imageOptions.maxWidth;
    final int? imageQuality = imageOptions.imageQuality;

    if (imageQuality != null && (imageQuality < 0 || imageQuality > 100)) {
      throw ArgumentError.value(
        imageQuality,
        'imageQuality',
        'must be between 0 and 100',
      );
    }

    if (maxWidth != null && maxWidth < 0) {
      throw ArgumentError.value(maxWidth, 'maxWidth', 'cannot be negative');
    }

    if (maxHeight != null && maxHeight < 0) {
      throw ArgumentError.value(maxHeight, 'maxHeight', 'cannot be negative');
    }

    return MaxSize_V2(width: maxWidth, height: maxHeight);
  }

  MediaSelectionOptions_V2 _mediaOptionsToMediaSelectionOptions_V2(
    MediaOptions mediaOptions,
  ) {
    final MaxSize_V2 maxSize = _imageOptionsToMaxSize_V2WithValidation(
      mediaOptions.imageOptions,
    );

    final bool allowMultiple = mediaOptions.allowMultiple;
    final int? limit = mediaOptions.limit;

    if (!allowMultiple && limit != null) {
      throw ArgumentError.value(
        allowMultiple,
        'allowMultiple',
        'cannot be false, when limit is not null',
      );
    }

    if (limit != null && limit < 2) {
      throw ArgumentError.value(limit, 'limit', 'cannot be lower than 2');
    }

    return MediaSelectionOptions_V2(
      maxSize: maxSize,
      imageQuality: mediaOptions.imageOptions.imageQuality,
      requestFullMetadata: mediaOptions.imageOptions.requestFullMetadata,
      allowMultiple: mediaOptions.allowMultiple,
      limit: mediaOptions.limit,
    );
  }

  @override
  Future<PickedFile?> pickVideo({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
  }) async {
    final String? path = await _pickVideoAsPath(
      source: source,
      maxDuration: maxDuration,
      preferredCameraDevice: preferredCameraDevice,
    );
    return path != null ? PickedFile(path) : null;
  }

  Future<String?> _pickVideoAsPath({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
  }) {
    return _hostApi.pickVideo(
      SourceSpecification_V2(
        type: _convertSource(source),
        camera: _convertCamera(preferredCameraDevice),
      ),
      maxDuration?.inSeconds,
    );
  }

  @override
  Future<XFile?> getImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    final String? path = await _pickImageAsPath(
      source: source,
      options: ImagePickerOptions(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        preferredCameraDevice: preferredCameraDevice,
      ),
    );
    return path != null ? XFile(path) : null;
  }

  @override
  Future<List<XFile>?> getMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    final List<String> paths = await _pickMultiImageAsPath(
      options: MultiImagePickerOptions(
        imageOptions: ImageOptions(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: imageQuality,
        ),
      ),
    );
    // Convert an empty list to a null return since that was the legacy behavior
    // of this method.
    if (paths.isEmpty) {
      return null;
    }

    return paths.map((String path) => XFile(path)).toList();
  }

  @override
  Future<XFile?> getVideo({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
  }) async {
    final String? path = await _pickVideoAsPath(
      source: source,
      maxDuration: maxDuration,
      preferredCameraDevice: preferredCameraDevice,
    );
    return path != null ? XFile(path) : null;
  }

  @override
  Future<List<XFile>> getMultiVideoWithOptions({
    MultiVideoPickerOptions options = const MultiVideoPickerOptions(),
  }) async {
    return (await _hostApi.pickMultiVideo(
      options.maxDuration?.inSeconds,
      options.limit,
    )).map((String path) => XFile(path)).toList();
  }
}
