//
//  RootViewController.m
//  slide
//
//  Created by Jack Dent on 10/09/2014.
//  Copyright (c) 2014 slide. All rights reserved.
//

#import "QRReaderViewController.h"
#import "AFHTTPRequestOperationManager.h"
#import "FormTableViewController.h"

@implementation QRReaderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [self startReading];
}

#pragma mark - QRCode reader

- (void)startReading {
    NSError *error;
    _stoppedCapture = NO;
    
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    if (!input) {
        NSLog(@"%@", [error localizedDescription]);
    } else {
        _captureSession = [[AVCaptureSession alloc] init];
        [_captureSession addInput:input];
        
        AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
        [_captureSession addOutput:captureMetadataOutput];
        
        dispatch_queue_t dispatchQueue;
        dispatchQueue = dispatch_queue_create("myQueue", NULL);
        [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
        [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
        
        _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
        [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        [_videoPreviewLayer setFrame:_scanPreview.layer.bounds];
        [_scanPreview.layer addSublayer:_videoPreviewLayer];
        
        [_captureSession startRunning];
    }
}

- (void)showForm {
    FormTableViewController *formEditor = [self.storyboard instantiateViewControllerWithIdentifier:@"FormTableViewController"];
    formEditor.form = _form;
    [self.navigationController pushViewController:formEditor animated:YES];
}

- (void)queryBackend {
    _form = @{};
    /*
     AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
     NSString *path = [NSString stringWithFormat:@"http://169.254.216.164:3000/forms/%@", [metadataObj stringValue]];
     [manager GET:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
     NSLog(@"JSON: %@", responseObject);
     _form = (NSDictionary *)responseObject;
     [self performSegueWithIdentifier:@"readerToDisplay" sender:self];
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
     NSLog(@"Error");
     }];
     */
    [self showForm];
}

- (void)stopReading {
    [_captureSession stopRunning];
    _captureSession = nil;
    [_videoPreviewLayer removeFromSuperlayer];
    
    [self queryBackend];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode] && !_stoppedCapture) {
            [self performSelectorOnMainThread:@selector(stopReading) withObject:nil waitUntilDone:NO];
            _stoppedCapture = YES;
            
            return;
        }
    }
}

@end