//
//  SOSImageManager.m
//  Photo Booth
//
//  Created by Sam Symons on 1/16/2014.
//  Copyright (c) 2014 Sam Symons. All rights reserved.
//

@import CoreImage;

#import "SOSImageManager.h"
#import "UIImage+Resize.h"

dispatch_queue_t imageProcessingQueue() {
    static dispatch_once_t once;
    static dispatch_queue_t queue;
    
    dispatch_once(&once, ^{
        queue = dispatch_queue_create("com.samsymons.photobooth.image-processing-queue", DISPATCH_QUEUE_SERIAL);
    });
    
    return queue;
}

@interface SOSImageManager ()

+ (NSString *)imageDirectoryPath;
+ (NSURL *)randomImageURL;
+ (NSString *)randomFileName;

/**
 Returns all of the images in the documents directory, sorted by modification date.
 */
+ (NSArray *)allImagePaths;

@end

@implementation SOSImageManager

+ (BOOL)serializeImage:(UIImage *)image
{
    UIImage *thumbnail = [image resizedImageToFitInSize:CGSizeMake(200.0f, 200.0f) scaleIfSmaller:NO];
    
    // Apply a Core Image filter:
    
    CIContext *context = [CIContext contextWithOptions:nil];
    
    CIImage *mainImage = [CIImage imageWithCGImage:[image CGImage]];
    CIImage *thumbnailImage = [CIImage imageWithCGImage:[thumbnail CGImage]];
    
    // Filter the main image:
    
    CIFilter *mainSepiaFilter = [CIFilter filterWithName:@"CISepiaTone" keysAndValues: kCIInputImageKey, mainImage, @"inputIntensity", @0.7, nil];
    CIImage *mainOutputImage = [mainSepiaFilter outputImage];
    
    CGImageRef filteredCGImage = [context createCGImage:mainOutputImage fromRect:[mainOutputImage extent]];
    UIImage *filteredImage = [UIImage imageWithCGImage:filteredCGImage];
    
    CGImageRelease(filteredCGImage);
    
    // Filter the thumbnail:
    
    CIFilter *thumbnailSepiaFilter = [CIFilter filterWithName:@"CISepiaTone" keysAndValues: kCIInputImageKey, thumbnailImage, @"inputIntensity", @0.7, nil];
    CIImage *thumbnailOutputImage = [thumbnailSepiaFilter outputImage];
    
    CGImageRef filteredCGImageThumbnail = [context createCGImage:thumbnailOutputImage fromRect:[thumbnailOutputImage extent]];
    UIImage *filteredThumbnail = [UIImage imageWithCGImage:filteredCGImageThumbnail];
    
    CGImageRelease(filteredCGImageThumbnail);
    
    // Save the images to disk:
    
    NSURL *imageURL = [SOSImageManager randomImageURL];
    NSString *imageURLString = [imageURL absoluteString];
    NSURL *thumbnailURL = [SOSImageManager thumbnailPathForImage:imageURLString];
    
    NSData *imageData = UIImageJPEGRepresentation(filteredImage, 1.0);
    NSData *thumbnailData = UIImageJPEGRepresentation(filteredThumbnail, 1.0);
    
    NSError *writeError = nil;
    NSError *thumbnailWriteError = nil;
    
    [imageData writeToURL:imageURL options:NSDataWritingAtomic error:&writeError];
    [thumbnailData writeToURL:thumbnailURL options:NSDataWritingAtomic error:&writeError];
    
    if (writeError)
    {
        NSLog(@"Failed to write image to disk: %@", writeError);
    }
    
    if (thumbnailWriteError)
    {
        NSLog(@"Failed to write thumbnail to disk: %@", thumbnailWriteError);
    }
    
    return (writeError == nil);
}

+ (NSArray *)imagePaths;
{
    NSArray *allImagePaths = [SOSImageManager allImagePaths];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT(absoluteString ENDSWITH 'thumbnail')"];
    
    return [allImagePaths filteredArrayUsingPredicate:predicate];
}

+ (NSArray *)imageThumbnailPaths
{
    NSArray *allImagePaths = [SOSImageManager allImagePaths];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"absoluteString ENDSWITH 'thumbnail'"];
    
    return [allImagePaths filteredArrayUsingPredicate:predicate];
}

+ (NSURL *)thumbnailPathForImage:(NSString *)imagePath
{
    return [NSURL URLWithString:[imagePath stringByAppendingString:@"-thumbnail"]];
}

+ (NSURL *)imagePathForThumbnail:(NSString *)thumbnailPath
{
    if ([thumbnailPath hasSuffix:@"-thumbnail"])
    {
        return [NSURL URLWithString:[thumbnailPath stringByReplacingOccurrencesOfString:@"-thumbnail" withString:@""]];
    }
    
    return nil;
}

#pragma mark - Private

+ (NSString *)imageDirectoryPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *imagesDirectory = [documentsDirectory stringByAppendingPathComponent:@"Images"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSError *error = nil;
    if (![fileManager fileExistsAtPath:imagesDirectory])
    {
        [fileManager createDirectoryAtPath:imagesDirectory withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    if (error)
    {
        return nil;
    }
    
    return imagesDirectory;
}

+ (NSURL *)randomImageURL
{
    NSString *imagePath = [[SOSImageManager imageDirectoryPath] stringByAppendingPathComponent:[SOSImageManager randomFileName]];
    return [NSURL fileURLWithPath:imagePath];
}

+ (NSString *)randomFileName
{
    return [[NSUUID UUID] UUIDString];
}

+ (NSArray *)allImagePaths
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *imageDirectoryURL = [NSURL URLWithString:[SOSImageManager imageDirectoryPath]];
    
    NSArray *contents = [fileManager contentsOfDirectoryAtURL:imageDirectoryURL includingPropertiesForKeys:@[] options:kNilOptions error:nil];
    NSArray *sortedContents = [contents sortedArrayUsingComparator:^(NSURL *firstFile, NSURL *secondFile) {
        NSDate *firstFileDate;
        [firstFile getResourceValue:&firstFileDate forKey:NSURLContentModificationDateKey error:nil];
        
        NSDate *secondFileDate;
        [secondFile getResourceValue:&secondFileDate forKey:NSURLContentModificationDateKey error:nil];
        
        return [firstFileDate compare: secondFileDate];
    }];
    
    return sortedContents;
}

@end
