//
//  SOSPhotosViewController.m
//  Photo Booth
//
//  Created by Sam Symons on 1/16/2014.
//  Copyright (c) 2014 Sam Symons. All rights reserved.
//

#import "SOSPhotosViewController.h"
#import "SOSPhotosLayout.h"
#import "SOSPhotoCell.h"
#import "SOSImageManager.h"

NSString *const SOSPhotoCellReuseIdentifier = @"SOSPhotoCellReuseIdentifier";

@interface SOSPhotosViewController ()

@property (nonatomic, strong) NSArray *imagePaths;

- (void)dismissPhotosViewController;
- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer;

@end

@implementation SOSPhotosViewController

- (id)init
{
    SOSPhotosLayout *photosLayout = [[SOSPhotosLayout alloc] init];
    if (self = [super initWithCollectionViewLayout:photosLayout])
    {
        self.title = NSLocalizedString(@"Captured Photos", @"Captured Photos");
        self.collectionView.alwaysBounceVertical = YES;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.imagePaths = [SOSImageManager imageThumbnailPaths];
    
    [[self collectionView] registerClass:[SOSPhotoCell class] forCellWithReuseIdentifier:SOSPhotoCellReuseIdentifier];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(dismissModalViewControllerAnimated:)];
    
    UILongPressGestureRecognizer *gestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    gestureRecognizer.delegate = self;
    
    [[self collectionView] addGestureRecognizer:gestureRecognizer];
}

#pragma mark - Private

- (void)dismissPhotosViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan)
    {
        return;
    }
    
    CGPoint point = [gestureRecognizer locationInView:self.collectionView];
    NSIndexPath *indexPath = [[self collectionView] indexPathForItemAtPoint:point];
    
    if (indexPath)
    {
        NSURL *thumbnailPath = self.imagePaths[indexPath.row];
        NSURL *imageURL = [SOSImageManager imagePathForThumbnail:[thumbnailPath absoluteString]];
        
        NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
        UIImage *image = [[UIImage alloc] initWithData:imageData];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[image] applicationActivities:nil];
            [self presentViewController:activityViewController animated:YES completion:nil];
        });
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[self imagePaths] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SOSPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:SOSPhotoCellReuseIdentifier forIndexPath:indexPath];
    
    NSURL *imagePath = self.imagePaths[indexPath.row];
    NSData *imageData = [NSData dataWithContentsOfURL:imagePath];
    UIImage *image = [[UIImage alloc] initWithData:imageData];
    
    [cell setImage:image];
    
    return cell;
}

@end
