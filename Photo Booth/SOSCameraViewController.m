//
//  SOSCameraViewController.m
//  Photo Booth
//
//  Created by Sam Symons on 1/16/2014.
//  Copyright (c) 2014 Sam Symons. All rights reserved.
//

#import "SOSCameraViewController.h"

#define TOTAL_PHOTOS_TO_TAKE 5

dispatch_queue_t metadataHandlingQueue() {
    static dispatch_once_t once;
    static dispatch_queue_t queue;
    
    dispatch_once(&once, ^{
        queue = dispatch_queue_create("com.samsymons.photobooth.metadata-handling-queue", DISPATCH_QUEUE_SERIAL);
    });
    
    return queue;
}

@interface SOSCameraViewController ()

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *captureDevice;

@property (nonatomic, strong) AVCaptureDeviceInput *captureDeviceInput;
@property (nonatomic, strong) AVCaptureMetadataOutput *metadataOutput;
@property (nonatomic, strong) CALayer *faceDetectionIndicationLayer;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, strong) NSTimer *captureTimer;

@property (nonatomic, assign, getter = isCapturingPhotos) BOOL capturingPhotos;
@property (nonatomic, strong) UIView *flashView;
@property (nonatomic, assign) NSUInteger numberOfPhotosTaken;

- (AVCaptureDevice *)frontCamera;

- (void)beginCapturingPhotos;
- (void)stopCapturingPhotos;

- (void)showFaceDetectionLayer;
- (void)hideFaceDetectionLayer;

- (void)capturePhoto;

- (void)flashScreen;

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
    }
    
    self.metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeFace];
    
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
        [_metadataOutput setMetadataObjectsDelegate:self queue:metadataHandlingQueue()];
    }
    
    return _metadataOutput;
}

- (CALayer *)faceDetectionIndicationLayer
{
    if (!_faceDetectionIndicationLayer)
    {
        _faceDetectionIndicationLayer = [CALayer layer];
        _faceDetectionIndicationLayer.cornerRadius = 5.0;
        
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

- (void)beginCapturingPhotos
{
    NSLog(@"Hold still... capturing photos!");
    
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
    [[self flashView] removeFromSuperview];
    
    NSLog(@"All done!");
}

- (void)capturePhoto
{
    // TODO: Actually capture frame.
    
    [self flashScreen];
    
    self.numberOfPhotosTaken++;
    if (self.numberOfPhotosTaken >= TOTAL_PHOTOS_TO_TAKE)
    {
        [self stopCapturingPhotos];
    }
}

- (void)flashScreen
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.flashView.alpha = 1.0;
        
        [UIView animateWithDuration:0.45 delay:0.1 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.flashView.alpha = 0.0;
        } completion:nil];
    });
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    AVMetadataFaceObject *detectedFaceMetadataObject = [metadataObjects firstObject];
    AVMetadataObject *transformedFaceMetadataObject = [[self previewLayer] transformedMetadataObjectForMetadataObject:detectedFaceMetadataObject];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (transformedFaceMetadataObject.bounds.size.width == 0.0 && transformedFaceMetadataObject.bounds.size.height == 0.0)
        {
            self.faceDetectionIndicationLayer.opacity = 0.0;
        }
        else
        {
            self.faceDetectionIndicationLayer.frame = transformedFaceMetadataObject.bounds;
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
