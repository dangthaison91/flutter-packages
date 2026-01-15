// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    objcHeaderOut:
        'ios/image_picker_ios/Sources/image_picker_ios/include/image_picker_ios/messages.g.h',
    objcSourceOut: 'ios/image_picker_ios/Sources/image_picker_ios/messages.g.m',
    objcOptions: ObjcOptions(
      prefix: 'FLT',
      headerIncludePath: './include/image_picker_ios/messages.g.h',
    ),
    copyrightHeader: 'pigeons/copyright.txt',
  ),
)
class MaxSize_V2 {
  MaxSize_V2(this.width, this.height);
  double? width;
  double? height;
}

class MediaSelectionOptions_V2 {
  MediaSelectionOptions_V2({
    required this.maxSize,
    this.imageQuality,
    required this.requestFullMetadata,
    required this.allowMultiple,
    this.limit,
  });

  MaxSize_V2 maxSize;
  int? imageQuality;
  bool requestFullMetadata;
  bool allowMultiple;
  int? limit;
}

// Corresponds to `CameraDevice` from the platform interface package.
enum SourceCamera_V2 { rear, front }

// Corresponds to `ImageSource` from the platform interface package.
enum SourceType_V2 { camera, gallery }

class SourceSpecification_V2 {
  SourceSpecification_V2(this.type, this.camera);
  SourceType_V2 type;
  SourceCamera_V2 camera;
}

@HostApi()
abstract class ImagePickerApi_V2 {
  @async
  @ObjCSelector('pickImageWithSource:maxSize:quality:fullMetadata:')
  String? pickImage(
    SourceSpecification_V2 source,
    MaxSize_V2 maxSize,
    int? imageQuality,
    bool requestFullMetadata,
  );
  @async
  @ObjCSelector('pickMultiImageWithMaxSize:quality:fullMetadata:limit:')
  List<String> pickMultiImage(
    MaxSize_V2 maxSize,
    int? imageQuality,
    bool requestFullMetadata,
    int? limit,
  );
  @async
  @ObjCSelector('pickVideoWithSource:maxDuration:')
  String? pickVideo(SourceSpecification_V2 source, int? maxDurationSeconds);
  @async
  @ObjCSelector('pickMultiVideoWithMaxDuration:limit:')
  List<String> pickMultiVideo(int? maxDurationSeconds, int? limit);

  /// Selects images and videos and returns their paths.
  @async
  @ObjCSelector('pickMediaWithMediaSelectionOptions:')
  List<String> pickMedia(MediaSelectionOptions_V2 mediaSelectionOptions);
}
