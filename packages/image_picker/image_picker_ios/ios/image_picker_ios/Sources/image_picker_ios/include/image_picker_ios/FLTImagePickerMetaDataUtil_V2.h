// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
  FLTImagePickerMIMETypePNG_V2,
  FLTImagePickerMIMETypeJPEG_V2,
  FLTImagePickerMIMETypeGIF_V2,
  FLTImagePickerMIMETypeOther_V2,
} FLTImagePickerMIMEType_V2;

extern NSString *const kFLTImagePickerDefaultSuffix_V2;
extern const FLTImagePickerMIMEType_V2 kFLTImagePickerMIMETypeDefault_V2;

@interface FLTImagePickerMetaDataUtil_V2 : NSObject

// Retrieve MIME type by reading the image data. We currently only support some popular types.
+ (FLTImagePickerMIMEType_V2)getImageMIMETypeFromImageData:(NSData *)imageData;

// Get corresponding surfix from type.
+ (nullable NSString *)imageTypeSuffixFromType:(FLTImagePickerMIMEType_V2)type;

+ (NSDictionary *)getMetaDataFromImageData:(NSData *)imageData;

// Creates and returns data for a new image based on imageData, but with the
// given metadata.
//
// If creating a new image fails, returns nil.
+ (nullable NSData *)imageFromImage:(NSData *)imageData withMetaData:(NSDictionary *)metadata;

// Converting UIImage to a NSData with the type proveide.
//
// The quality is for JPEG type only, it defaults to 1. It throws exception if setting a non-nil
// quality with type other than FLTImagePickerMIMETypeJPEG_V2. Converting UIImage to
// FLTImagePickerMIMETypeGIF_V2 or FLTImagePickerMIMETypeTIFF_V2 is not supported in iOS. This
// method throws exception if trying to do so.
+ (nonnull NSData *)convertImage:(nonnull UIImage *)image
                       usingType:(FLTImagePickerMIMEType_V2)type
                         quality:(nullable NSNumber *)quality;

@end

NS_ASSUME_NONNULL_END
