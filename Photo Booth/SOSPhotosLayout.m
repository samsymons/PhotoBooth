//
//  SOSPhotosLayout.m
//  Photo Booth
//
//  Created by Sam Symons on 1/16/2014.
//  Copyright (c) 2014 Sam Symons. All rights reserved.
//

#import "SOSPhotosLayout.h"

@implementation SOSPhotosLayout

- (id)init
{
    if (self = [super init])
    {
        self.itemSize = CGSizeMake(100, 100);
        self.minimumInteritemSpacing = 5;
        self.minimumLineSpacing = 5;
        self.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5);
    }
    
    return self;
}

@end
