// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>

#import "FLTImagePickerImageUtil.h"
#import "FLTImagePickerMetaDataUtil.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLTImagePickerPhotoAssetUtil : NSObject

+ (nullable PHAsset *)getAssetFromImagePickerInfo:(NSDictionary *)info;

// Saves video to temporary URL. Returns nil on failure;
+ (NSURL *)saveVideoFromURL:(NSURL *)videoURL;

// Saves image with correct meta data and extention copied from the original asset.
// maxWidth and maxHeight are used only for GIF images.
+ (NSString *)saveImageWithOriginalImageData:(NSData *)originalImageData
                                       image:(UIImage *)image
                                    maxWidth:(nullable NSNumber *)maxWidth
                                   maxHeight:(nullable NSNumber *)maxHeight
                                imageQuality:(nullable NSNumber *)imageQuality;

// Save image with correct meta data and extention copied from image picker result info.
+ (NSString *)saveImageWithPickerInfo:(nullable NSDictionary *)info
                                image:(UIImage *)image
                         imageQuality:(nullable NSNumber *)imageQuality;

// Get a temporary file path with the given suffix.
+ (NSString *)temporaryFilePath:(NSString *)suffix;

// Save a GIF image with metadata.
+ (NSString *)saveImageWithMetaData:(nullable NSDictionary *)metaData
                            gifInfo:(GIFInfo *)gifInfo
                             suffix:(NSString *)suffix;

// Save a static image with metadata.
+ (NSString *)saveImageWithMetaData:(nullable NSDictionary *)metaData
                              image:(UIImage *)image
                             suffix:(NSString *)suffix
                               type:(FLTImagePickerMIMEType)type
                       imageQuality:(nullable NSNumber *)imageQuality;

@end

NS_ASSUME_NONNULL_END
