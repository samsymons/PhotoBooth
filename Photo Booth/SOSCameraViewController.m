//
//  SOSCameraViewController.m
//  Photo Booth
//
//  Created by Sam Symons on 1/16/2014.
//  Copyright (c) 2014 Sam Symons. All rights reserved.
//

@import AssetsLibrary;

#import "SOSCameraViewController.h"
#import "SOSPhotosViewController.h"
#import "SOSImageManager.h"

#define TOTAL_PHOTOS_TO_TAKE 5

dispatch_queue_t imageCaptureQueue() {
    static dispatch_once_t once;
    static dispatch_queue_t queue;
    
    dispatch_once(&once, ^{
        queue = dispatch_queue_create("com.samsymons.photobooth.image-capture-queue", DISPATCH_QUEUE_SERIAL);
    });
    
    return queue;
}

dispatch_queue_t metadataProcessingQueue() {
    static dispatch_once_t once;
    static dispatch_queue_t queue;
    
    dispatch_once(&once, ^{
        queue = dispatch_queue_create("com.samsymons.photobooth.metadata-processing-queue", DISPATCH_QUEUE_SERIAL);
    });
    
    return queue;
}

@interface SOSCameraViewController ()

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *captureDevice;

@property (nonatomic, strong) AVCaptureDeviceInput *captureDeviceInput;
@property (nonatomic, strong) AVCaptureMetadataOutput *metadataOutput;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;

@property (nonatomic, strong) CALayer *faceDetectionIndicationLayer;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, assign, getter = isCapturingPhotos) BOOL capturingPhotos;
@property (nonatomic, strong) NSTimer *captureTimer;
@property (nonatomic, strong) UIView *flashView;
@property (nonatomic, assign) NSUInteger numberOfPhotosTaken;

- (AVCaptureDevice *)frontCamera;

- (void)checkCameraAccessStatus;

- (void)beginCapturingPhotos;
- (void)stopCapturingPhotos;

- (void)capturePhoto;
- (void)flashScreen;

- (void)presentPhotosViewController;

@end

@implementation SOSCameraViewController

- (id)init
{
    if (self = [super initWithNibName:nil bundle:nil])
    {
        self.view.backgroundColor = [UIColor blackColor];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self checkCameraAccessStatus];
    
    // Set up the capture session:
    
    self.captureSession = [[AVCaptureSession alloc] init];
    self.captureDevice = [self frontCamera];
    
    self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    self.numberOfPhotosTaken = 0;
    
    // Add the device input:
    
    NSError *deviceInputError;
    self.captureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.captureDevice error:&deviceInputError];
    
    if ([[self captureSession] canAddInput:self.captureDeviceInput])
    {
        [[self captureSession] addInput:self.captureDeviceInput];
    }
    
    // Add the metadata output:
    
    if ([[self captureSession] canAddOutput:self.metadataOutput])
    {
        [[self captureSession] addOutput:self.metadataOutput];
        
        self.metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeFace];
    }
    
    // Add the still image output:
    
    if ([[self captureSession] canAddOutput:self.stillImageOutput])
    {
        [[self stillImageOutput] setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
        [[self captureSession] addOutput:self.stillImageOutput];
    }
    
    // Add the preview layer and start capturing:
    
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    self.previewLayer.frame = self.view.frame;
    
    [[[self view] layer] addSublayer:self.previewLayer];
    
    [[self captureSession] startRunning];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (AVCaptureMetadataOutput *)metadataOutput
{
    if (!_metadataOutput)
    {
        _metadataOutput = [[AVCaptureMetadataOutput alloc] init];
        [_metadataOutput setMetadataObjectsDelegate:self queue:metadataProcessingQueue()];
    }
    
    return _metadataOutput;
}

- (AVCaptureStillImageOutput *)stillImageOutput
{
    if (!_stillImageOutput)
    {
        _stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    }
    
    return _stillImageOutput;
}

- (CALayer *)faceDetectionIndicationLayer
{
    if (!_faceDetectionIndicationLayer)
    {
        _faceDetectionIndicationLayer = [CALayer layer];
        _faceDetectionIndicationLayer.cornerRadius = 6.0;
        
        _faceDetectionIndicationLayer.borderColor = [[UIColor colorWithRed:1.00 green:0.68 blue:0.00 alpha:1.0] CGColor];
        _faceDetectionIndicationLayer.borderWidth = 1.0;
        _faceDetectionIndicationLayer.backgroundColor = [[UIColor clearColor] CGColor];
        
        [[self previewLayer] addSublayer:_faceDetectionIndicationLayer];
    }
    
    return  _faceDetectionIndicationLayer;
}

#pragma mark - Private

- (AVCaptureDevice *)frontCamera
{
    for (AVCaptureDevice *device in [AVCaptureDevice devices])
    {
        if ([device hasMediaType:AVMediaTypeVideo] && [device position] == AVCaptureDevicePositionFront)
        {
            return device;
        }
    }
    
    return nil;
}

- (void)checkCameraAccessStatus
{
    NSString *mediaType = AVMediaTypeVideo;
	[AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
		if (!granted)
		{
			NSLog(@"Cannot access the camera!");
		}
	}];
}

- (void)beginCapturingPhotos
{
    self.flashView = [[UIView alloc] initWithFrame:self.view.frame];
    self.flashView.alpha = 0.0;
    self.flashView.backgroundColor = [UIColor whiteColor];
    
    [[self view] addSubview:self.flashView];
    
    self.captureTimer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(capturePhoto) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.captureTimer forMode:NSDefaultRunLoopMode];
}

- (void)stopCapturingPhotos
{
    [[self captureTimer] invalidate];
    self.captureTimer = nil;
    
    self.capturingPhotos = NO;
    
    [[self captureSession] removeOutput:self.metadataOutput];
    [[self flashView] removeFromSuperview];
}

- (void)capturePhoto
{
    dispatch_async(imageCaptureQueue(), ^{
        AVCaptureConnection *connection = [[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo];
        
        [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        
        [self flashScreen];
        
		[[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            self.numberOfPhotosTaken++;
            
			if (!imageDataSampleBuffer)
			{
                NSLog(@"Failed to capture image, with error: %@", error);
                return;
            }
            
			NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *image = [UIImage imageWithData:imageData];
            
            [SOSImageManager serializeImage:image completion:^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.numberOfPhotosTaken >= TOTAL_PHOTOS_TO_TAKE)
                    {
                        [self stopCapturingPhotos];
                        [self presentPhotosViewController];
                    }
                });
            }];
		}];
	});
}

- (void)flashScreen
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.flashView.alpha = 1.0;
        
        [UIView animateWithDuration:0.55 delay:0.1 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.flashView.alpha = 0.0;
        } completion:nil];
    });
}

- (void)presentPhotosViewController
{
    SOSPhotosViewController *photosViewController = [[SOSPhotosViewController alloc] init];
    UINavigationController *photosNavigationController = [[UINavigationController alloc] initWithRootViewController:photosViewController];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:photosNavigationController animated:YES completion:nil];
    });
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    AVMetadataFaceObject *faceMetadata = [metadataObjects firstObject];
    AVMetadataFaceObject *transformedFaceMetadata = (AVMetadataFaceObject *)[[self previewLayer] transformedMetadataObjectForMetadataObject:faceMetadata];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (transformedFaceMetadata.bounds.size.width == 0.0 && transformedFaceMetadata.bounds.size.height == 0.0)
        {
            self.faceDetectionIndicationLayer.opacity = 0.0;
        }
        else
        {
            if (self.faceDetectionIndicationLayer.opacity == 0.0)
            {
                self.faceDetectionIndicationLayer.opacity = 1.0;
            }
            
            self.faceDetectionIndicationLayer.frame = transformedFaceMetadata.bounds;
        }
    });
    
    if (!self.isCapturingPhotos)
    {
        self.capturingPhotos = YES;
        
        __weak __typeof(self)weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf beginCapturingPhotos];
        });
    }
}

@end
