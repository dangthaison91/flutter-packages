// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <PhotosUI/PhotosUI.h>

#import "FLTImagePickerImageUtil_V2.h"
#import "FLTImagePickerMetaDataUtil_V2.h"
#import "FLTImagePickerPhotoAssetUtil_V2.h"

NS_ASSUME_NONNULL_BEGIN

/// Returns either the saved path, or an error. Both cannot be set.
typedef void (^FLTGetSavedPath)(NSString *_Nullable savedPath, FlutterError *_Nullable error);

/// @class FLTPHPickerSaveImageToPathOperation_V2
///
/// @brief The FLTPHPickerSaveImageToPathOperation_V2 class
///
/// @discussion    This class was implemented to handle saved image paths and populate the pathList
/// with the final result by using GetSavedPath type block.
///
/// @superclass SuperClass: NSOperation\n
/// @helps It helps FLTImagePickerPlugin_V2 class.
@interface FLTPHPickerSaveImageToPathOperation_V2 : NSOperation

- (instancetype)initWithResult:(PHPickerResult *)result
                     maxHeight:(NSNumber *)maxHeight
                      maxWidth:(NSNumber *)maxWidth
           desiredImageQuality:(NSNumber *)desiredImageQuality
                  fullMetadata:(BOOL)fullMetadata
                savedPathBlock:(FLTGetSavedPath)savedPathBlock API_AVAILABLE(ios(14));

@end

NS_ASSUME_NONNULL_END
