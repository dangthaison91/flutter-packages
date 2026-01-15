// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTImagePickerMetaDataUtil_V2.h"
#import <Photos/Photos.h>

static const uint8_t kFirstByteJPEG = 0xFF;
static const uint8_t kFirstBytePNG = 0x89;
static const uint8_t kFirstByteGIF = 0x47;

NSString *const kFLTImagePickerDefaultSuffix_V2 = @".jpg";
const FLTImagePickerMIMEType_V2 kFLTImagePickerMIMETypeDefault_V2 = FLTImagePickerMIMETypeJPEG_V2;

@implementation FLTImagePickerMetaDataUtil_V2

+ (FLTImagePickerMIMEType_V2)getImageMIMETypeFromImageData:(NSData *)imageData {
  uint8_t firstByte;
  [imageData getBytes:&firstByte length:1];
  switch (firstByte) {
    case kFirstByteJPEG:
      return FLTImagePickerMIMETypeJPEG_V2;
    case kFirstBytePNG:
      return FLTImagePickerMIMETypePNG_V2;
    case kFirstByteGIF:
      return FLTImagePickerMIMETypeGIF_V2;
  }
  return FLTImagePickerMIMETypeOther_V2;
}

+ (NSString *)imageTypeSuffixFromType:(FLTImagePickerMIMEType_V2)type {
  switch (type) {
    case FLTImagePickerMIMETypeJPEG_V2:
      return @".jpg";
    case FLTImagePickerMIMETypePNG_V2:
      return @".png";
    case FLTImagePickerMIMETypeGIF_V2:
      return @".gif";
    default:
      return nil;
  }
}

+ (NSDictionary *)getMetaDataFromImageData:(NSData *)imageData {
  CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
  NSDictionary *metadata =
      (NSDictionary *)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source, 0, NULL));
  CFRelease(source);
  return metadata;
}

+ (NSData *)imageFromImage:(NSData *)imageData withMetaData:(NSDictionary *)metadata {
  NSMutableData *targetData = [NSMutableData data];
  CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
  if (source == NULL) {
    return nil;
  }
  CGImageDestinationRef destination = NULL;
  CFStringRef sourceType = CGImageSourceGetType(source);
  if (sourceType != NULL) {
    destination =
        CGImageDestinationCreateWithData((__bridge CFMutableDataRef)targetData, sourceType, 1, nil);
  }
  if (destination == NULL) {
    CFRelease(source);
    return nil;
  }
  CGImageDestinationAddImageFromSource(destination, source, 0, (__bridge CFDictionaryRef)metadata);
  CGImageDestinationFinalize(destination);
  CFRelease(source);
  CFRelease(destination);
  return targetData;
}

+ (NSData *)convertImage:(UIImage *)image
               usingType:(FLTImagePickerMIMEType_V2)type
                 quality:(nullable NSNumber *)quality {
  if (quality && type != FLTImagePickerMIMETypeJPEG_V2) {
    NSLog(@"image_picker: compressing is not supported for type %@. Returning the image with "
          @"original quality",
          [FLTImagePickerMetaDataUtil_V2 imageTypeSuffixFromType:type]);
  }

  switch (type) {
    case FLTImagePickerMIMETypeJPEG_V2: {
      CGFloat qualityFloat = (quality != nil) ? quality.floatValue : 1;
      return UIImageJPEGRepresentation(image, qualityFloat);
    }
    case FLTImagePickerMIMETypePNG_V2:
      return UIImagePNGRepresentation(image);
    default: {
      // converts to JPEG by default.
      CGFloat qualityFloat = (quality != nil) ? quality.floatValue : 1;
      return UIImageJPEGRepresentation(image, qualityFloat);
    }
  }
}

@end
