//
//  VRViewController.m
//  VideoRecorder
//
//  Created by Simon CORSIN on 8/3/13.
//  Copyright (c) 2013 SCorsin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "VideoRecordViewController.h"
#import "FilterViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "ProgressHUD.h"


#define kVideoPreset AVCaptureSessionPresetHigh

////////////////////////////////////////////////////////////
// PRIVATE DEFINITION
/////////////////////

@interface VideoRecordViewController () {

}

@property (weak, nonatomic) IBOutlet UIButton *btnaddphoto;
@property (weak, nonatomic) IBOutlet UIButton *btnuploadvideo;

@end

////////////////////////////////////////////////////////////
// IMPLEMENTATION
/////////////////////

@implementation VideoRecordViewController

#pragma mark - UIViewController

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_0

- (UIStatusBarStyle) preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

#endif

#pragma mark - Left cycle
- (IBAction)clickswitchcamera:(id)sender {
    [self.cam switchCamera];
    
}
- (IBAction)clicknext:(id)sender {
    self.cam.radialView.progressCounter = 0;
    [self.nextitem setEnabled:NO];
    [self.cam saveVideoWithCompletionBlock:^(BOOL success) {
        if (success)
        {
            
            [NSThread detachNewThreadSelector:@selector(createFilterVideo:) toTarget:self withObject:nil];
            
            
            NSLog(@"WILL PUSH NEW CONTROLLER HERE");
            
        }
        
    }];
    
}

-(void)createFilterVideo:(id)sender
{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *path =  [documentsDirectory stringByAppendingPathComponent:
                       [NSString stringWithFormat:@"mergeVideo.mp4"]];
    
    NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:path];
    //
    //    NSURL *outputURL = [[NSBundle mainBundle] URLForResource:@"sample_iPod" withExtension:@"m4v"];
    
    
    movieFile = [[GPUImageMovie alloc] initWithURL:outputURL];
    movieFile.runBenchmark = YES;
    movieFile.playAtActualSpeed = NO;

//    filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"valencia"];
    
    filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"nashiville"];
    filter1 = [[GPUImageLevelsFilter alloc]init];
    [filter1 setBlueMin:0.0 gamma:1.0 max:1.0 minOut:49.0f/255.0f maxOut:1.0];
    
    
    [movieFile addTarget:filter];
    [movieFile addTarget:filter1];
    
    
    
    // In addition to displaying to the screen, write out a processed version of the movie to disk
    
    filterVideo  = [[NSString alloc] initWithString:[NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"filter.%@", @"mp4"]]];
    
    unlink([filterVideo UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    NSURL *newmovieURL = [NSURL fileURLWithPath:filterVideo];
    
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:newmovieURL size:CGSizeMake(480.0, 480.0)];
    [filter addTarget:movieWriter];
    [filter1 addTarget:movieWriter];
    
    // Configure this for video from the movie file, where we want to preserve all video frames and audio samples
    movieWriter.shouldPassthroughAudio = YES;
    movieFile.audioEncodingTarget = movieWriter;
    [movieFile enableSynchronizedEncodingUsingMovieWriter:movieWriter];
    
    [movieWriter startRecording];
    [movieFile startProcessing];
    
    
    [movieWriter setCompletionBlock:^{
        
        
        [filter removeTarget:movieWriter];
        [filter1 removeTarget:movieWriter];
        [movieWriter finishRecording];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:@"videogofilter" sender:sender];
            [ProgressHUD dismiss];
            
        });
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
  
    self.cam = [[KZCameraView alloc]initWithFrame:CGRectMake(0.0, 64.0, self.view.frame.size.width, self.view.frame.size.height - 64.0) withVideoPreviewFrame:CGRectMake(0.0, 0.0, 320.0, 320.0)];
    self.cam.maxDuration = 8.0;
    self.cam.showCameraSwitch = YES; //Say YES to button to switch between front and back cameras
    
    self.cam.nextitem = self.nextitem;
    [self.view addSubview:self.cam];
    [self.nextitem setEnabled:NO];
   
    [self.view bringSubviewToFront:self.btnaddphoto];
    [self.view bringSubviewToFront:self.btnuploadvideo];
    
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:58/255.0f green:29/255.0f blue:59/255.0f alpha:1.0f]];
    [self.view setBackgroundColor:[UIColor colorWithRed:58/255.0f green:29/255.0f blue:59/255.0f alpha:1.0f]];
    
//    [radialView addGestureRecognizer:[[SCTouchDetector alloc] initWithTarget:self action:@selector(handleTouchDetected:)]];
    
    CGSize screen = [UIScreen mainScreen].bounds.size;
    
    
    self.btnaddphoto.center = CGPointMake(screen.width/5*4, 384 + (screen.height-384)/2);
    
    
    self.btnuploadvideo.center = CGPointMake(screen.width/5, 384 + (screen.height-384)/2);
    
   
    
    
    
}



- (void)viewWillAppear:(BOOL)animated {
	self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    
    
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
    
   
}



#pragma mark - Handle

- (void)showAlertViewWithTitle:(NSString*)title message:(NSString*) message {
    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alertView show];
}


-(IBAction)clickback:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"videogofilter"]){
        FilterViewController  *controller = segue.destinationViewController;
      
   
        controller.linkVideo = filterVideo;
    }
}



@end