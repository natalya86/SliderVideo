//
//  VideoSelectViewController.m
//  SliderVideo
//
//  Created by admin on 7/25/14.
//  Copyright (c) 2014 tinystone. All rights reserved.
//

#import "VideoSelectViewController.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "FilterViewController.h"
#import "ProgressHUD.h"
@interface VideoSelectViewController ()

@end

@implementation VideoSelectViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor colorWithRed:58/255.0f green:29/255.0f blue:59/255.0f alpha:1.0f]];
    
    CGRect rcScreen = [[UIScreen mainScreen]bounds];
    
    [self.selbtn setCenter:CGPointMake(rcScreen.size.width/2, 64+(rcScreen.size.height-64-70)/2)];
    
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(IBAction)clickselectvideo:(id)sender
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie,nil];

    
    [self presentViewController:picker animated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    
    if (CFStringCompare ((__bridge CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
        videoUrl=(NSURL*)[info objectForKey:UIImagePickerControllerMediaURL];
        videopath = [videoUrl path];
        
       
    }
    
    [self dismissModalViewControllerAnimated:YES];
   
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

- (IBAction)clickincludefilter:(id)sender {
    
    self.checkfilter.selected =  !self.checkfilter.selected;
    
    
    
    
}
-(void)viewWillAppear:(BOOL)animated
{
    [self.m_itemnext setEnabled:YES];
    [self.m_itemback setEnabled:YES];
    [self.checkfilter setEnabled:YES];
    [self.selbtn setEnabled:YES];
}
- (IBAction)clicknext:(id)sender {
    [self.m_itemnext setEnabled:NO];
    [self.m_itemback setEnabled:NO];
    [self.checkfilter setEnabled:NO];
    [self.selbtn setEnabled:NO];
        if (videoUrl != nil)
        {
            [ProgressHUD show:@"Please wait"];
            
            
            [self CropVideoSquare];
            
            
            
        }
   
    
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"videogofilter"]){
        FilterViewController  *controller = segue.destinationViewController;
        
        
        controller.linkVideo = filterVideo;
    }
}
-(void)createFilterVideo:(id)sender
{
    
    NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:videopath];
    //
    //    NSURL *outputURL = [[NSBundle mainBundle] URLForResource:@"sample_iPod" withExtension:@"m4v"];
    
    
    movieFile = [[GPUImageMovie alloc] initWithURL:outputURL];
    movieFile.runBenchmark = YES;
    movieFile.playAtActualSpeed = NO;
    
    filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"valencia"];
    
//    filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"nashiville"];
//    filter1 = [[GPUImageLevelsFilter alloc]init];
//    [filter1 setBlueMin:0.0 gamma:1.0 max:1.0 minOut:49.0f/255.0f maxOut:1.0];
    
    
    [movieFile addTarget:filter];
//    [movieFile addTarget:filter1];
    
    
    
    // In addition to displaying to the screen, write out a processed version of the movie to disk
    
    filterVideo  = [[NSString alloc] initWithString:[NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"filter.%@", @"mp4"]]];
    
    unlink([filterVideo UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    NSURL *newmovieURL = [NSURL fileURLWithPath:filterVideo];
    
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:newmovieURL size:CGSizeMake(480.0, 480.0)];
    
    
    [filter addTarget:movieWriter];
//    [filter1 addTarget:movieWriter];
    
    
    // Configure this for video from the movie file, where we want to preserve all video frames and audio samples
    movieWriter.shouldPassthroughAudio = YES;
    movieFile.audioEncodingTarget = movieWriter;
    [movieFile enableSynchronizedEncodingUsingMovieWriter:movieWriter];
    
    [movieWriter startRecording];
    [movieFile startProcessing];
    
    
    [movieWriter setCompletionBlock:^{
        
        
        [filter removeTarget:movieWriter];
//        [filter1 removeTarget:movieWriter];
        [movieWriter finishRecording];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:@"videogofilter" sender:sender];
            [ProgressHUD dismiss];
            
        });
    }];
}

-(IBAction)clickback:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) CropVideoSquare{
    
    //load our movie Asset
    AVAsset *asset = [AVAsset assetWithURL:videoUrl];
    
    //create an avassetrack with our asset
    AVAssetTrack *clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    //create a video composition and preset some settings
    AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.frameDuration = CMTimeMake(1, 30);
    //here we are setting its render size to its height x height (Square)
    videoComposition.renderSize = CGSizeMake(480, 480);
    
    //create a video instruction
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(8, 30));
    
    AVMutableVideoCompositionLayerInstruction* transformer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:clipVideoTrack];
    
    //Here we shift the viewing square up to the TOP of the video so we only see the top
    CGAffineTransform t1 = CGAffineTransformMakeTranslation(clipVideoTrack.naturalSize.height, 0 );
    
    //Use this code if you want the viewing square to be in the middle of the video
    //CGAffineTransform t1 = CGAffineTransformMakeTranslation(clipVideoTrack.naturalSize.height, -(clipVideoTrack.naturalSize.width - clipVideoTrack.naturalSize.height) /2 );
    
    //Make sure the square is portrait
    CGAffineTransform t2 = CGAffineTransformRotate(t1, M_PI_2);
    
    CGAffineTransform finalTransform = t2;
    [transformer setTransform:finalTransform atTime:kCMTimeZero];
    
    //add the transformer layer instructions, then add to video composition
    instruction.layerInstructions = [NSArray arrayWithObject:transformer];
    videoComposition.instructions = [NSArray arrayWithObject: instruction];
    
    //Create an Export Path to store the cropped video
    NSString * documentsPath = [[NSString alloc] initWithString:NSTemporaryDirectory()];
    NSString *exportPath = [documentsPath stringByAppendingFormat:@"/CroppedVideo.mp4"];
    NSURL *exportUrl = [NSURL fileURLWithPath:exportPath];
    
    //Remove any prevouis videos at that path
    [[NSFileManager defaultManager]  removeItemAtURL:exportUrl error:nil];
    
    //Export
    exporter = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetHighestQuality] ;
    exporter.videoComposition = videoComposition;
    exporter.outputURL = exportUrl;
    exporter.outputFileType = AVFileTypeMPEG4;
    
	[exporter exportAsynchronouslyWithCompletionHandler:^
     {
         dispatch_async(dispatch_get_main_queue(), ^{
             //Call when finished
             [self exportDidFinish:exporter];
         });
     }];
}


- (void)exportDidFinish:(AVAssetExportSession*)session
{
    //Play the New Cropped video
    NSURL *outputURL = session.outputURL;
    videopath = outputURL.path;
    
    if (self.checkfilter.selected) {
        
        [NSThread detachNewThreadSelector:@selector(createFilterVideo:) toTarget:self withObject:nil];
    }else
    {
        [ProgressHUD dismiss];
        filterVideo = videopath;
        [self performSegueWithIdentifier:@"videogofilter" sender:nil];
    }

}


@end
