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

+ (CIContext *)imageContext;

+ (NSString *)imageDirectoryPath;
+ (NSURL *)randomImageURL;
+ (NSString *)randomFileName;

/**
 Returns all of the images in the documents directory, sorted by modification date.
 */
+ (NSArray *)allImagePaths;

+ (UIImage *)imageWithSepiaFilter:(UIImage *)image;

@end

@implementation SOSImageManager

+ (BOOL)serializeImage:(UIImage *)image
{
    UIImage *thumbnail = [image imageScaledToFillSize:CGSizeMake(200.0, 200.0)];
    
    // Filter the images:
    
    UIImage *filteredImage = [SOSImageManager imageWithSepiaFilter:image];
    UIImage *filteredThumbnail = [SOSImageManager imageWithSepiaFilter:thumbnail];
    
    // Save the images to disk:
    
    NSURL *imageURL = [SOSImageManager randomImageURL];
    NSURL *thumbnailURL = [SOSImageManager thumbnailPathForImage:[imageURL absoluteString]];
    
    NSData *imageData = UIImageJPEGRepresentation(filteredImage, 1.0);
    NSData *thumbnailData = UIImageJPEGRepresentation(filteredThumbnail, 1.0);
    
    NSError *writeError = nil;
    NSError *thumbnailWriteError = nil;
    
    [imageData writeToURL:imageURL options:NSDataWritingAtomic error:&writeError];
    [thumbnailData writeToURL:thumbnailURL options:NSDataWritingAtomic error:&thumbnailWriteError];
    
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

+ (CIContext *)imageContext
{
    static dispatch_once_t once;
    static CIContext *context;
    
    dispatch_once(&once, ^{
        context = [CIContext contextWithOptions:nil];
    });
    
    return context;
}

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

+ (UIImage *)imageWithSepiaFilter:(UIImage *)image
{
    CIImage *imageToFilter = [CIImage imageWithCGImage:[image CGImage]];
    
    CIFilter *thumbnailSepiaFilter = [CIFilter filterWithName:@"CISepiaTone" keysAndValues: kCIInputImageKey, imageToFilter, @"inputIntensity", @0.7, nil];
    CIImage *thumbnailOutputImage = [thumbnailSepiaFilter outputImage];
    
    CGImageRef filteredCGImage = [[SOSImageManager imageContext] createCGImage:thumbnailOutputImage fromRect:[thumbnailOutputImage extent]];
    UIImage *filteredImage = [UIImage imageWithCGImage:filteredCGImage];
    
    CGImageRelease(filteredCGImage);
    
    return filteredImage;
}

@end
