// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTImagePickerPhotoAssetUtil_V2.h"
#import "FLTImagePickerImageUtil_V2.h"
#import "FLTImagePickerMetaDataUtil_V2.h"

#import <MobileCoreServices/MobileCoreServices.h>

@implementation FLTImagePickerPhotoAssetUtil_V2

+ (PHAsset *)getAssetFromImagePickerInfo:(NSDictionary *)info {
  return info[UIImagePickerControllerPHAsset];
}

+ (NSURL *)saveVideoFromURL:(NSURL *)videoURL {
  if (![[NSFileManager defaultManager] isReadableFileAtPath:[videoURL path]]) {
    return nil;
  }
  NSString *fileName = [videoURL lastPathComponent];
  NSURL *destination = [NSURL fileURLWithPath:[self temporaryFilePath:fileName]];
  NSError *error;
  [[NSFileManager defaultManager] copyItemAtURL:videoURL toURL:destination error:&error];
  if (error) {
    return nil;
  }
  return destination;
}

+ (NSString *)saveImageWithOriginalImageData:(NSData *)originalImageData
                                       image:(UIImage *)image
                                    maxWidth:(NSNumber *)maxWidth
                                   maxHeight:(NSNumber *)maxHeight
                                imageQuality:(NSNumber *)imageQuality {
  NSString *suffix = kFLTImagePickerDefaultSuffix_V2;
  FLTImagePickerMIMEType_V2 type = kFLTImagePickerMIMETypeDefault_V2;
  NSDictionary *metaData = nil;
  // Getting the image type from the original image data if necessary.
  if (originalImageData) {
    type = [FLTImagePickerMetaDataUtil_V2 getImageMIMETypeFromImageData:originalImageData];
    suffix =
        [FLTImagePickerMetaDataUtil_V2 imageTypeSuffixFromType:type] ?: kFLTImagePickerDefaultSuffix_V2;
    metaData = [FLTImagePickerMetaDataUtil_V2 getMetaDataFromImageData:originalImageData];
  }
  if (type == FLTImagePickerMIMETypeGIF_V2) {
    GIFInfo_V2 *gifInfo = [FLTImagePickerImageUtil_V2 scaledGIFImage:originalImageData
                                                      maxWidth:maxWidth
                                                     maxHeight:maxHeight];

    return [self saveImageWithMetaData:metaData gifInfo:gifInfo suffix:suffix];
  } else {
    return [self saveImageWithMetaData:metaData
                                 image:image
                                suffix:suffix
                                  type:type
                          imageQuality:imageQuality];
  }
}

+ (NSString *)saveImageWithPickerInfo:(nullable NSDictionary *)info
                                image:(UIImage *)image
                         imageQuality:(NSNumber *)imageQuality {
  NSDictionary *metaData = info[UIImagePickerControllerMediaMetadata];
  return [self saveImageWithMetaData:metaData
                               image:image
                              suffix:kFLTImagePickerDefaultSuffix_V2
                                type:kFLTImagePickerMIMETypeDefault_V2
                        imageQuality:imageQuality];
}

+ (NSString *)saveImageWithMetaData:(NSDictionary *)metaData
                            gifInfo:(GIFInfo_V2 *)gifInfo
                             suffix:(NSString *)suffix {
  NSString *path = [self temporaryFilePath:suffix];
  return [self saveImageWithMetaData:metaData gifInfo:gifInfo path:path];
}

+ (NSString *)saveImageWithMetaData:(NSDictionary *)metaData
                              image:(UIImage *)image
                             suffix:(NSString *)suffix
                               type:(FLTImagePickerMIMEType_V2)type
                       imageQuality:(NSNumber *)imageQuality {
  NSData *data = [FLTImagePickerMetaDataUtil_V2 convertImage:image
                                                usingType:type
                                                  quality:imageQuality];
  if (metaData) {
    NSData *updatedData = [FLTImagePickerMetaDataUtil_V2 imageFromImage:data withMetaData:metaData];
    // If updating the metadata fails, just save the original.
    if (updatedData) {
      data = updatedData;
    }
  }

  return [self createFile:data suffix:suffix];
}

+ (NSString *)saveImageWithMetaData:(NSDictionary *)metaData
                            gifInfo:(GIFInfo_V2 *)gifInfo
                               path:(NSString *)path {
  CGImageDestinationRef destination = CGImageDestinationCreateWithURL(
      (__bridge CFURLRef)[NSURL fileURLWithPath:path], kUTTypeGIF, gifInfo.images.count, NULL);

  NSDictionary *frameProperties = @{
    (__bridge NSString *)kCGImagePropertyGIFDictionary : @{
      (__bridge NSString *)kCGImagePropertyGIFDelayTime : @(gifInfo.interval),
    },
  };

  NSMutableDictionary *gifMetaProperties = [NSMutableDictionary dictionaryWithDictionary:metaData];
  NSMutableDictionary *gifProperties =
      (NSMutableDictionary *)gifMetaProperties[(NSString *)kCGImagePropertyGIFDictionary];
  if (gifMetaProperties == nil) {
    gifProperties = [NSMutableDictionary dictionary];
  }

  gifProperties[(__bridge NSString *)kCGImagePropertyGIFLoopCount] = @0;

  CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)gifMetaProperties);

  for (NSInteger index = 0; index < gifInfo.images.count; index++) {
    UIImage *image = (UIImage *)[gifInfo.images objectAtIndex:index];
    CGImageDestinationAddImage(destination, image.CGImage,
                               (__bridge CFDictionaryRef)frameProperties);
  }

  CGImageDestinationFinalize(destination);
  CFRelease(destination);

  return path;
}

+ (NSString *)temporaryFilePath:(NSString *)suffix {
  NSString *fileExtension = [@"image_picker_%@" stringByAppendingString:suffix];
  NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString];
  NSString *tmpFile = [NSString stringWithFormat:fileExtension, guid];
  NSString *tmpDirectory = NSTemporaryDirectory();
  NSString *tmpPath = [tmpDirectory stringByAppendingPathComponent:tmpFile];
  return tmpPath;
}

+ (NSString *)createFile:(NSData *)data suffix:(NSString *)suffix {
  NSString *tmpPath = [self temporaryFilePath:suffix];
  if ([[NSFileManager defaultManager] createFileAtPath:tmpPath contents:data attributes:nil]) {
    return tmpPath;
  } else {
    nil;
  }
  return tmpPath;
}

@end
