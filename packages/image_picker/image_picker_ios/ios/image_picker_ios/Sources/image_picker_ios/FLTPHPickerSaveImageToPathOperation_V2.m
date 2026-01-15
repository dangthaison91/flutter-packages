// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

#import "FLTPHPickerSaveImageToPathOperation_V2.h"

#import <os/log.h>

API_AVAILABLE(ios(14))
@interface FLTPHPickerSaveImageToPathOperation_V2 ()

@property(strong, nonatomic) PHPickerResult *result;
@property(strong, nonatomic) NSNumber *maxHeight;
@property(strong, nonatomic) NSNumber *maxWidth;
@property(strong, nonatomic) NSNumber *desiredImageQuality;
@property(assign, nonatomic) BOOL requestFullMetadata;

@end

@implementation FLTPHPickerSaveImageToPathOperation_V2 {
  BOOL executing;
  BOOL finished;
  FLTGetSavedPath getSavedPath;
}

- (instancetype)initWithResult:(PHPickerResult *)result
                     maxHeight:(NSNumber *)maxHeight
                      maxWidth:(NSNumber *)maxWidth
           desiredImageQuality:(NSNumber *)desiredImageQuality
                  fullMetadata:(BOOL)fullMetadata
                savedPathBlock:(FLTGetSavedPath)savedPathBlock API_AVAILABLE(ios(14)) {
  if (self = [super init]) {
    if (result) {
      self.result = result;
      self.maxHeight = maxHeight;
      self.maxWidth = maxWidth;
      self.desiredImageQuality = desiredImageQuality;
      self.requestFullMetadata = fullMetadata;
      getSavedPath = savedPathBlock;
      executing = NO;
      finished = NO;
    } else {
      return nil;
    }
    return self;
  } else {
    return nil;
  }
}

- (BOOL)isConcurrent {
  return YES;
}

- (BOOL)isExecuting {
  return executing;
}

- (BOOL)isFinished {
  return finished;
}

- (void)setFinished:(BOOL)isFinished {
  [self willChangeValueForKey:@"isFinished"];
  self->finished = isFinished;
  [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)isExecuting {
  [self willChangeValueForKey:@"isExecuting"];
  self->executing = isExecuting;
  [self didChangeValueForKey:@"isExecuting"];
}

- (void)completeOperationWithPath:(NSString *)savedPath error:(FlutterError *)error {
  getSavedPath(savedPath, error);
  [self setExecuting:NO];
  [self setFinished:YES];
}

- (void)start {
  if ([self isCancelled]) {
    [self setFinished:YES];
    return;
  }
  if (@available(iOS 14, *)) {
    [self setExecuting:YES];

    if ([self.result.itemProvider hasItemConformingToTypeIdentifier:UTTypeImage.identifier]) {
      [self processImage];
    } else if ([self.result.itemProvider
                   // This supports uniform types that conform to UTTypeMovie.
                   // This includes kUTTypeVideo, kUTTypeMPEG4, public.3gpp, kUTTypeMPEG,
                   // public.3gpp2, public.avi, kUTTypeQuickTimeMovie.
                   hasItemConformingToTypeIdentifier:UTTypeMovie.identifier]) {
      [self processVideo];
    } else {
      FlutterError *flutterError = [FlutterError errorWithCode:@"invalid_source"
                                                       message:@"Invalid media source."
                                                       details:nil];
      [self completeOperationWithPath:nil error:flutterError];
    }
  } else {
    [self setFinished:YES];
  }
}

/// Processes the image.
- (void)processImage API_AVAILABLE(ios(14)) {
  NSString *typeIdentifier = [self preferredTypeIdentifierForItemProvider:self.result.itemProvider];

  [self.result.itemProvider
      loadFileRepresentationForTypeIdentifier:typeIdentifier
                            completionHandler:^(NSURL *_Nullable url, NSError *_Nullable error) {
                              if (url == nil) {
                                [self completeWithError:error];
                                return;
                              }

                              if ([self canDirectlyCopyFile]) {
                                [self directlyCopyFileFromURL:url];
                              } else {
                                NSData *data = [NSData dataWithContentsOfURL:url];
                                [self processImageWithData:data];
                              }
                            }];
}

/// Returns the image quality normalized to 0-1 range.
/// If quality is nil, returns 1.0. If quality > 1, assumes 0-100 scale and normalizes.
- (CGFloat)normalizedImageQuality {
  if (self.desiredImageQuality == nil) {
    return 1.0;
  }
  CGFloat quality = self.desiredImageQuality.floatValue;
  // If quality is > 1, assume it's in 0-100 scale and normalize to 0-1.
  if (quality > 1.0) {
    quality = quality / 100.0;
  }
  // Clamp to valid range.
  return MIN(1.0, MAX(0.0, quality));
}

/// Returns YES if the image can be copied directly without processing.
- (BOOL)canDirectlyCopyFile {
  BOOL noResizeNeeded = (self.maxWidth == nil && self.maxHeight == nil);
  CGFloat quality = [self normalizedImageQuality];
  // Allow direct copy if quality is effectively 1 (full quality).
  BOOL noQualityReduction = (quality >= 0.99);
  return noResizeNeeded && noQualityReduction;
}

/// Copies the file directly to temporary storage without decoding/re-encoding.
- (void)directlyCopyFileFromURL:(NSURL *)sourceURL {
  NSString *extension = [sourceURL.pathExtension lowercaseString];
  if (extension.length > 0) {
    extension = [@"." stringByAppendingString:extension];
  }

  NSString *destinationPath = [FLTImagePickerPhotoAssetUtil_V2 temporaryFilePath:extension];
  NSError *copyError;
  [[NSFileManager defaultManager] copyItemAtURL:sourceURL
                                          toURL:[NSURL fileURLWithPath:destinationPath]
                                          error:&copyError];

  if (copyError) {
    FlutterError *flutterError =
        [FlutterError errorWithCode:@"copy_error"
                            message:@"Could not copy image to temporary directory"
                            details:copyError.localizedDescription];
    [self completeOperationWithPath:nil error:flutterError];
  } else {
    [self completeOperationWithPath:destinationPath error:nil];
  }
}

/// Completes the operation with an error from the system.
- (void)completeWithError:(NSError *)error {
  FlutterError *flutterError = [FlutterError errorWithCode:@"invalid_image"
                                                   message:error.localizedDescription
                                                   details:error.domain];
  [self completeOperationWithPath:nil error:flutterError];
}

- (void)processImageWithData:(NSData *)pickerImageData API_AVAILABLE(ios(14)) {
  if (pickerImageData == nil) {
    FlutterError *flutterError = [FlutterError errorWithCode:@"invalid_image"
                                                     message:@"Image data is nil."
                                                     details:nil];
    [self completeOperationWithPath:nil error:flutterError];
    return;
  }

  UIImage *localImage = nil;
  BOOL resizeRequested = (self.maxWidth != nil || self.maxHeight != nil);

  // Use ImageIO for memory-efficient resizing (decodes directly to target size)
  if (resizeRequested) {
    localImage = [FLTImagePickerImageUtil_V2 scaledImageFromData:pickerImageData
                                                     maxWidth:self.maxWidth
                                                    maxHeight:self.maxHeight];
  }

  // If scaledImageFromData returned nil, it means ImageIO couldn't resize or no resize was needed.
  // Fall back to full decode.
  if (localImage == nil) {
    localImage = [[UIImage alloc] initWithData:pickerImageData];
    if (localImage == nil) {
      FlutterError *flutterError = [FlutterError errorWithCode:@"invalid_image"
                                                       message:@"Could not decode image data."
                                                       details:nil];
      [self completeOperationWithPath:nil error:flutterError];
      return;
    }
    // If resize was requested but ImageIO failed, use legacy scaling method.
    if (resizeRequested) {
      localImage = [FLTImagePickerImageUtil_V2 scaledImage:localImage
                                               maxWidth:self.maxWidth
                                              maxHeight:self.maxHeight
                                    isMetadataAvailable:self.requestFullMetadata];
    }
  }

  // Normalize quality to 0-1 range for downstream use.
  NSNumber *normalizedQuality = @([self normalizedImageQuality]);

  // Logic unrolled from FLTImagePickerPhotoAssetUtil_V2 saveImageWithOriginalImageData
  // to allow conditional metadata stripping logic.

  FLTImagePickerMIMEType_V2 type = kFLTImagePickerMIMETypeDefault_V2;
  NSString *suffix = kFLTImagePickerDefaultSuffix_V2;
  NSDictionary *metaData = nil;

  // 1. Detect Type & Suffix
  if (pickerImageData) {
    type = [FLTImagePickerMetaDataUtil_V2 getImageMIMETypeFromImageData:pickerImageData];
    suffix =
        [FLTImagePickerMetaDataUtil_V2 imageTypeSuffixFromType:type] ?: kFLTImagePickerDefaultSuffix_V2;
  }

  // 2. Extract Metadata (ONLY if requested)
  if (self.requestFullMetadata && pickerImageData) {
    metaData = [FLTImagePickerMetaDataUtil_V2 getMetaDataFromImageData:pickerImageData];
  }

  NSString *savedPath = nil;

  // 3. Handle GIF vs Standard
  if (type == FLTImagePickerMIMETypeGIF_V2) {
    GIFInfo_V2 *gifInfo = [FLTImagePickerImageUtil_V2 scaledGIFImage:pickerImageData
                                                      maxWidth:self.maxWidth
                                                     maxHeight:self.maxHeight];
    savedPath = [FLTImagePickerPhotoAssetUtil_V2 saveImageWithMetaData:metaData
                                                            gifInfo:gifInfo
                                                             suffix:suffix];
  } else {
    savedPath = [FLTImagePickerPhotoAssetUtil_V2 saveImageWithMetaData:metaData
                                                              image:localImage
                                                             suffix:suffix
                                                               type:type
                                                       imageQuality:normalizedQuality];
  }

  [self completeOperationWithPath:savedPath error:nil];
}

/// Processes the video.
- (void)processVideo API_AVAILABLE(ios(14)) {
  NSString *typeIdentifier = self.result.itemProvider.registeredTypeIdentifiers.firstObject;
  [self.result.itemProvider
      loadFileRepresentationForTypeIdentifier:typeIdentifier
                            completionHandler:^(NSURL *_Nullable videoURL,
                                                NSError *_Nullable error) {
                              if (error != nil) {
                                FlutterError *flutterError =
                                    [FlutterError errorWithCode:@"invalid_image"
                                                        message:error.localizedDescription
                                                        details:error.domain];
                                [self completeOperationWithPath:nil error:flutterError];
                                return;
                              }

                              NSURL *destination =
                                  [FLTImagePickerPhotoAssetUtil_V2 saveVideoFromURL:videoURL];
                              if (destination == nil) {
                                [self
                                    completeOperationWithPath:nil
                                                        error:[FlutterError
                                                                  errorWithCode:
                                                                      @"flutter_image_picker_copy_"
                                                                      @"video_error"
                                                                        message:@"Could not cache "
                                                                                @"the video file."
                                                                        details:nil]];
                                return;
                              }

                              [self completeOperationWithPath:[destination path] error:nil];
                            }];
}

#pragma mark - Helpers

/// Returns the preferred UTType identifier for the given item provider.
/// Uses the first registered image type, falling back to generic UTTypeImage.
- (NSString *)preferredTypeIdentifierForItemProvider:(NSItemProvider *)itemProvider
    API_AVAILABLE(ios(14)) {
  // Use the first registered type that conforms to UTTypeImage.
  // This preserves the original format (HEIC, PNG, JPEG, WebP, etc.) without
  // needing to maintain a hardcoded list.
  for (NSString *identifier in itemProvider.registeredTypeIdentifiers) {
    UTType *type = [UTType typeWithIdentifier:identifier];
    if (type != nil && [type conformsToType:UTTypeImage]) {
      return identifier;
    }
  }

  // Fallback to generic image type (system will transcode if needed)
  return UTTypeImage.identifier;
}

@end
