//
//  SOSImageManagerTests.m
//  Photo Booth
//
//  Created by Sam Symons on 1/17/2014.
//  Copyright (c) 2014 Sam Symons. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SOSImageManager.h"

@interface SOSImageManagerTests : XCTestCase

@end

@implementation SOSImageManagerTests

- (void)testThumbnailURLCalculation
{
    NSString *imagePath = @"file://somefile";
    NSString *thumbnailPath = [SOSImageManager thumbnailPathForImage:imagePath];
    
    XCTAssertEqual(thumbnailPath, @"file://somefile-thumbnail", @"The image paths should be equal.");
}

- (void)testImageURLCalculation
{
    NSString *thumbnailPath = @"file://somefile-thumbnail";
    NSString *imagePath = [SOSImageManager imagePathForThumbnail:thumbnailPath];
    
    XCTAssertEqual(imagePath, @"file://somefile", @"The image paths should be equal.");
}

@end
