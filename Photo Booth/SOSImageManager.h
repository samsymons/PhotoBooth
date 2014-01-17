//
//  SOSImageManager.h
//  Photo Booth
//
//  Created by Sam Symons on 1/16/2014.
//  Copyright (c) 2014 Sam Symons. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^SOSImagesCompletionHandler)(NSArray *imagePaths, NSError *error);

@interface SOSImageManager : NSObject

/**
 Serializes an image to disk, along with a 100×100 thumbnail for it.
 
 @param image The image to serialize.
 */
+ (BOOL)serializeImage:(UIImage *)image;

/**
 Returns the paths of the images stored in the documents directory.
 The paths will be sorted by creation date.
 */
+ (NSArray *)imagePaths;

/**
 Returns the paths of the thumbnails stored in the documents directory.
 The paths will be sorted by creation date.
 */
+ (NSArray *)imageThumbnailPaths;

/**
 Returns the URL of an image's thumbnail.
 
 @param imagePath The path of the image.
 */
+ (NSURL *)thumbnailPathForImage:(NSString *)imagePath;

/**
 Returns the URL of a thumbnail's full-sized image.
 
 @param thumbnailPath The path of the thumbnail.
 */
+ (NSURL *)imagePathForThumbnail:(NSString *)thumbnailPath;

@end
