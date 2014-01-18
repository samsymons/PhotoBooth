//
//  SOSPhotoCell.m
//  Photo Booth
//
//  Created by Sam Symons on 1/16/2014.
//  Copyright (c) 2014 Sam Symons. All rights reserved.
//

#import "SOSPhotoCell.h"

@interface SOSPhotoCell ()

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation SOSPhotoCell

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [[UIColor colorWithWhite:1.0 alpha:0.2] CGColor];
        
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, frame.size.width, frame.size.height)];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.layer.masksToBounds = YES;
        
        [[self contentView] addSubview:_imageView];
    }
    
    return self;
}

- (void)setImage:(UIImage *)image
{
    self.imageView.image = image;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
