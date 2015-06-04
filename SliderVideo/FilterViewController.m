//
//  FilterViewController.m
//  SliderVideo
//
//  Created by admin on 7/2/14.
//  Copyright (c) 2014 tinystone. All rights reserved.
//

#import "FilterViewController.h"
#import "AudioRecordViewController.h"
#import "SEFilterControl.h"
#import "PCMMixer.h"


#import "ProgressHUD.h"
#import "CTAssetsPickerController.h"
#import "CTAssetsPageViewController.h"
#import <MessageUI/MessageUI.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreFoundation/CoreFoundation.h>
@interface FilterViewController ()

@end

@implementation FilterViewController
@synthesize mediaArray,shareFlag,exportedVideo,linkVideo;
@synthesize m_addrecord,m_previewVideo;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
-(IBAction)clickback:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) disableAllUI
{
    [self.scrollMenu setUserInteractionEnabled:NO];
    [self.m_addrecord setEnabled:NO];
    [self.m_itemnext setEnabled:NO];
    [self.m_itemback setEnabled:NO];
}

-(void) enableAllUI
{
    [self.scrollMenu setUserInteractionEnabled:YES];
    [self.m_addrecord setEnabled:YES];
    [self.m_itemnext setEnabled:YES];
    [self.m_itemback setEnabled:YES];
}

-(IBAction)clickcomplete:(id)sender
{
    [ProgressHUD show:@"Please wait"];
    [self.m_itemnext setEnabled:NO];
    NSURL* outputFileURL;
    if (exportedVideo != nil) {
        outputFileURL = [[NSURL alloc]initFileURLWithPath:exportedVideo];
    }else
        outputFileURL = [[NSURL alloc]initFileURLWithPath:linkVideo];
    
    
    AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:outputFileURL options:nil];
    
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo  preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *clipVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                                   ofTrack:clipVideoTrack
                                    atTime:kCMTimeZero error:nil];
    
    [compositionVideoTrack setPreferredTransform:[[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] preferredTransform]];
    
    UIImage *myImage = [UIImage imageNamed:@"logo.png"];
    CALayer *aLayer = [CALayer layer];
    aLayer.contents = (id)myImage.CGImage;
    aLayer.frame = CGRectMake(480-90, 480-54, 90, 54); //Needed for proper display. We are using the app icon (57x57). If you use 0,0 you will not see it
    aLayer.opacity = 0.65; //Feel free to alter the alpha here
    
    
    CGSize videoSize = [videoAsset naturalSize];
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:aLayer];
    
    
    AVMutableVideoComposition* videoComp = [AVMutableVideoComposition videoComposition];
    videoComp.renderSize = videoSize;
    videoComp.frameDuration = CMTimeMake(1, 30);
    videoComp.animationTool = [AVVideoCompositionCoreAnimationTool      videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mixComposition duration]);
    AVAssetTrack *videoTrack = [[mixComposition tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVMutableVideoCompositionLayerInstruction* layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    instruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];
    videoComp.instructions = [NSArray arrayWithObject: instruction];
    
    NSArray* audioarray =[videoAsset tracksWithMediaType:AVMediaTypeAudio];
    
    if (audioarray.count > 0) {
        AVAssetTrack * audioAssetTrack = [audioarray objectAtIndex:0];
        
        AVMutableCompositionTrack *compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID: kCMPersistentTrackID_Invalid];
        
        
        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,videoAsset.duration) ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
    }
    AVAssetExportSession * _assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];//AVAssetExportPresetPassthrough
    _assetExport.videoComposition = videoComp;
    
    NSString* videoName = @"slidevideomake.mp4";
    
    NSString *exportPath = [NSTemporaryDirectory() stringByAppendingPathComponent:videoName];
    NSURL    *exportUrl = [NSURL fileURLWithPath:exportPath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:exportPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:exportPath error:nil];
    }
    
    _assetExport.outputFileType = AVFileTypeMPEG4;
    _assetExport.outputURL = exportUrl;
    _assetExport.shouldOptimizeForNetworkUse = YES;
    
    
    [_assetExport exportAsynchronouslyWithCompletionHandler:
     ^(void ) {
         switch (_assetExport.status) {
             case AVAssetExportSessionStatusFailed:{
                 NSLog(@"Fail: %@", _assetExport.error);
                 break;
             }
             case AVAssetExportSessionStatusCompleted:{
                 NSLog(@"Success");
                 
                 dispatch_async(dispatch_get_main_queue(), ^{
                     UISaveVideoAtPathToSavedPhotosAlbum(exportPath, self,  @selector(video:didFinishSavingWithError:contextInfo:), nil);
                     
                     
                 });
                 
                 break;
             }
             default:
                 break;
         }
     }
     ];
    
    
    
    
    
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    filtertype = 0;
    
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:58/255.0f green:29/255.0f blue:59/255.0f alpha:1.0f]];
    [self.view setBackgroundColor:[UIColor colorWithRed:58/255.0f green:29/255.0f blue:59/255.0f alpha:1.0f]];
    
    
    
    if (linkVideo == nil) {
        [self startVideoConvert];
    }else
    {
        [self setPlayFile:linkVideo];
        [self StartPlayer];
    }
    
    
    self.picker = [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeMusic];
    self.picker.delegate						= self;
    self.picker.allowsPickingMultipleItems	= YES;
    self.picker.prompt						= NSLocalizedString (@"Add songs to play", "Prompt in media item picker");
    [self.picker setAllowsPickingMultipleItems:NO];
    
    self.voiceHud = [[POVoiceHUD alloc] initWithParentView:self.view];
    self.voiceHud.title = @"Speak Now";
    
    [self.voiceHud setDelegate:self];
    [self.view addSubview:self.voiceHud];
    
    [self setUpACPScroll];
    
    CGSize screen = [UIScreen mainScreen].bounds.size;
    if (screen.height > 480) {
        self.m_addrecord.center = CGPointMake(screen.width/2,(screen.height-384)/2);
    }
    
}

- (void)setUpACPScroll {
	NSMutableArray *array = [[NSMutableArray alloc] init];
	for (int i = 1; i < 7; i++)
    {
		NSString *imgName = [NSString stringWithFormat:@"audio%d.png", i];
		NSString *imgSelectedName = [NSString stringWithFormat:@"audio%ds.png", i];
        
		//You can choose between work with delegates or with blocks
		//This sample project has commented the delegate functionality
        
		//ACPItem *item = [[ACPItem alloc] initACPItem:[UIImage imageNamed:@"bg.png"] iconImage:[UIImage imageNamed:imgName] andLabel:@"Test"];
        
		//Item working with blocks
		ACPItem *item = [[ACPItem alloc] initACPItem:nil
                                           iconImage:[UIImage imageNamed:imgName]
                                               label:@""
                                           andAction: ^(ACPItem *item) {
                                               
                                               NSLog(@"Block called! %d", i);
                                               //DO somenthing here
                                           }];
        
		//Set highlighted behaviour
		[item setHighlightedBackground:nil iconHighlighted:[UIImage imageNamed:imgSelectedName] textColorHighlighted:[UIColor redColor]];
		[array addObject:item];
	}
    
	[_scrollMenu setUpACPScrollMenu:array];
    
	//We choose an animation when the user touch the item (you can create your own animation)
	[_scrollMenu setAnimationType:ACPZoomOut];
	_scrollMenu.delegate = self;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)startVideoConvert{
    [ProgressHUD show:@"Please wait..."];
    [self disableAllUI];
    [NSThread detachNewThreadSelector:@selector(createVideo) toTarget:self withObject:nil];
    
}

-(CGImageRef)scaleCGImage: (CGImageRef) image
{
    // Create the bitmap context
    CGContextRef context = NULL;
    void * bitmapData;
    int bitmapByteCount;
    int bitmapBytesPerRow;
    
    // Get image width, height. We'll use the entire image.
    int o_width = CGImageGetWidth(image);
    int o_height = CGImageGetHeight(image);
    int width,height;
    
    int o_size = 480 +transitionTimeStep*2;
    if (o_width > o_height) {
        height = o_size;
        width = o_size*o_width/o_height;
        
    }else
    {
        width = o_size;
        height = o_size*o_height/o_width;
    }
    
    
    // Declare the number of bytes per row. Each pixel in the bitmap in this
    // example is represented by 4 bytes; 8 bits each of red, green, blue, and
    // alpha.
    bitmapBytesPerRow = (width * 4);
    bitmapByteCount = (bitmapBytesPerRow * height);
    
    // Allocate memory for image data. This is the destination in memory
    // where any drawing to the bitmap context will be rendered.
    bitmapData = malloc( bitmapByteCount );
    if (bitmapData == NULL)
    {
        return nil;
    }
    
    // Create the bitmap context. We want pre-multiplied ARGB, 8-bits
    // per component. Regardless of what the source image format is
    // (CMYK, Grayscale, and so on) it will be converted over to the format
    // specified here by CGBitmapContextCreate.
    CGColorSpaceRef colorspace = CGImageGetColorSpace(image);
    context = CGBitmapContextCreate (bitmapData,width,height,8,bitmapBytesPerRow,
                                     colorspace,kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorspace);
    
    if (context == NULL)
        // error creating context
        return nil;
    
    // Draw the image to the bitmap context. Once we draw, the memory
    // allocated for the context for rendering will then contain the
    // raw image data in the specified color space.
    CGContextDrawImage(context, CGRectMake(0,0,width, height), image);
    
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    free(bitmapData);
    
    return imgRef;
}

- (void)createVideo{
    
    overlayref = [[UIImage imageNamed:@"overlay.png"] CGImage];
    
    linkVideo  = [[NSString alloc] initWithString:[NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"mp4"]]];
    
    NSLog(@"%@",linkVideo);
    
    
	AVAssetWriter *asset = [AVAssetWriter assetWriterWithURL:[NSURL fileURLWithPath:linkVideo] fileType:AVFileTypeQuickTimeMovie error:nil];
	
	NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
								   AVVideoCodecH264, AVVideoCodecKey,
								   [NSNumber numberWithInt:480], AVVideoWidthKey,
								   [NSNumber numberWithInt:480], AVVideoHeightKey,
								   nil];
	
	AVAssetWriterInput* writerInput = [AVAssetWriterInput
                                       assetWriterInputWithMediaType:AVMediaTypeVideo
                                       outputSettings:videoSettings];
	
	NSMutableDictionary *attributes = [[NSMutableDictionary alloc]init];
	[attributes setObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32ARGB] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
	[attributes setObject:[NSNumber numberWithUnsignedInt:480] forKey:(NSString*)kCVPixelBufferWidthKey];
	[attributes setObject:[NSNumber numberWithUnsignedInt:480] forKey:(NSString*)kCVPixelBufferHeightKey];
	
	AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
													 assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
													 sourcePixelBufferAttributes:attributes];
    
	
	[asset addInput:writerInput];
	
	// fixes all errors
	writerInput.expectsMediaDataInRealTime = YES;
	[asset startWriting];
	[asset startSessionAtSourceTime:kCMTimeZero];
	
	CVPixelBufferRef buffer = NULL;
	BOOL result;
	
    
    ALAsset *assettmp  = [mediaArray objectAtIndex:0];
    ALAssetRepresentation *rep = [assettmp defaultRepresentation];
    CGImageRef iref_o = [rep fullScreenImage];
    CGImageRef iref = [self scaleCGImage:iref_o];
    
    CGImageRef next_iref_o= nil;
    CGImageRef next_iref= nil;
    if (mediaArray.count > 1) {
        ALAsset *assettmp1  = [mediaArray objectAtIndex:1];
        ALAssetRepresentation *rep1 = [assettmp1 defaultRepresentation];
        next_iref_o = [rep1 fullScreenImage];
        next_iref = [self scaleCGImage:next_iref_o];
        int kkk = rand();
        if (CGImageGetHeight(next_iref) > CGImageGetWidth(next_iref)) {
            next_direction = kkk%2;
        }else
            next_direction = kkk%2+2;
    }
    
    
    
    
    
    
	buffer = [self pixelBufferFromCGImage:iref next_iref:next_iref dy:0];
	
	result = [adaptor appendPixelBuffer:buffer withPresentationTime:kCMTimeZero];
	if (result == NO) //failes on 3GS, but works on iphone 4
		NSLog(@"failed to append buffer");
	
	if(buffer)
		CVBufferRelease(buffer);
	
	[NSThread sleepForTimeInterval:0.1];
    int captureindex= 1;
    progressCount = 0;
    
    transitionTimeStep = 32;
	for (int i = 2;i < ([self.mediaArray count]*transitionTimeStep); i++)
	{
        
        progressCount = i;
		if (adaptor.assetWriterInput.readyForMoreMediaData)
		{
            
			NSLog(@"inside for loop %d",i);
			
            CMTime frameTime = CMTimeMake(1, 20);
			CMTime lastTime=CMTimeMake(i, 20);
			CMTime presentTime=CMTimeAdd(lastTime, frameTime);
            
            if (transitionTimeStep * captureindex+1 == i) {
                captureindex++;
                
                assettmp  = [mediaArray objectAtIndex:captureindex-1];
                rep = [assettmp defaultRepresentation];
                
                CGImageRelease(iref);
                CGImageRelease(next_iref);
                
                iref = [self scaleCGImage:[rep fullScreenImage]];
                
                
                if (mediaArray.count >  captureindex) {
                    ALAsset *assettmp1  = [mediaArray objectAtIndex:captureindex];
                    ALAssetRepresentation *rep1 = [assettmp1 defaultRepresentation];
                    next_iref = [self scaleCGImage:[rep1 fullScreenImage]];
                }else
                {
                    next_iref = nil;
                }
                
                direction = next_direction;
                
                if (CGImageGetHeight(next_iref) >= CGImageGetWidth(next_iref)) {
                    next_direction = random()*1000%2;
                }else
                    next_direction = random()*1000%2+2;
            }
            
            
            
			buffer = [self pixelBufferFromCGImage:iref next_iref:next_iref dy:(i-1)%transitionTimeStep];
			BOOL result = [adaptor appendPixelBuffer:buffer withPresentationTime:presentTime];
			
			if (result == NO) //failes on 3GS, but works on iphone 4
			{
                
                
                if (asset.status == AVAssetWriterStatusFailed) {
                    [ProgressHUD dismiss];
                    
                    [self performSelectorOnMainThread:@selector(failAlert) withObject:nil waitUntilDone:NO ];
                    return;
                }
			}
			if(buffer)
				CVBufferRelease(buffer);
            //            CGImageRelease(iref);
            //			[NSThread sleepForTimeInterval:0.1];
		}
		else
		{
            
			i--;
		}
        
	}
    
    
	
	//Finish the session:
	[writerInput markAsFinished];
	[asset performSelectorOnMainThread:@selector(finishWriting) withObject:nil waitUntilDone:YES];
	CVPixelBufferPoolRelease(adaptor.pixelBufferPool);
    
//    
//    CGImageRelease(overlayref)
    [self performSelectorOnMainThread:@selector(createVideoSuccessfully) withObject:nil waitUntilDone:YES ];
}
- (IBAction)clickreplay:(id)sender {
    if (playing) {
        [self.mPlayer pause];
        playing = false;
    }else
    {
        [self.mPlayer play];
        playing = true;
    }
    
}

-(void)createVideoSuccessfully{
    
    [ProgressHUD dismiss];
    [self enableAllUI];
    countImg = 0;
    
    
    [self.mPlayer setVolume:1.0];
    [self setPlayFile:linkVideo];
    [self StartPlayer];
    
    
    
}

- (void)video:(NSString *) videoPath didFinishSavingWithError: (NSError *) error1 contextInfo: (void *) contextInfo {
    
    [ProgressHUD dismiss];
    
    
    if(error1){
        
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message"
                                                        message:@"Save video to Gallery failed, please try again!"
                                                       delegate:self
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
        
        [alert show];
    }
    else {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message"
                                                        message:@"Save video to Gallery success!"
                                                       delegate:self
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
        
        [alert show];
        
    }
    
    
    
}

- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image next_iref:(CGImageRef) next_iref dy:(int)dy{
    
    int width = CGImageGetWidth(image);
    int height = CGImageGetHeight(image);
    float scalerate = (float)width/height;
    
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
	
    CVPixelBufferCreate(kCFAllocatorDefault, 480,
                        480, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                        &pxbuffer);
	
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
	
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, 480,
                                                 480, 8, 4*480, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
	
    
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    
    
    GPUImageToneCurveFilter* filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"valencia"];
    
//    GPUImageToneCurveFilter* filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"nashiville"];
//    GPUImageLevelsFilter *levelfilter = [[GPUImageLevelsFilter alloc]init];
//    [levelfilter setBlueMin:0.0 gamma:1.0 max:1.0 minOut:49.0f/255.0f maxOut:1.0];

    
    CGImageRef imageFilter;
    
    if (self.flagfilter) {
        imageFilter = [filter newCGImageByFilteringCGImage:image];
//        imageFilter = [levelfilter newCGImageByFilteringCGImage:imageFilter1];
    }else
        imageFilter = image;
        
    
    
    
    
    
    
    NSLog(@"width=%d, height=%d", width,height);
    if (direction == SLIDE_LEFT) {
        CGContextDrawImage(context, CGRectMake((480-width)/2+transitionTimeStep-dy*2, -(height-480)/2, width,height), imageFilter);
        
    }else if (direction == SLIDE_RIGHT)
    {
        CGContextDrawImage(context, CGRectMake((480-width)/2-transitionTimeStep+dy*2, -(height-480)/2, width,height), imageFilter);
        
    }else if (direction == SLIDE_UP)
    {
        
        CGContextDrawImage(context, CGRectMake(-(width-480)/2, (480-height)/2-transitionTimeStep+dy*2, width,height), imageFilter);
        
    }else
    {
        CGContextDrawImage(context, CGRectMake(-(width-480)/2, (480-height)/2+transitionTimeStep-dy*2, width,height), imageFilter);
    }
    
    
    GPUImageOpacityFilter *stillImageFilter2 = [[GPUImageOpacityFilter alloc] init];
    float Opacity = 0.0f;
    if (dy > 25) {
        Opacity =(sqrt(dy-20)*25.81)/100.0f;
        
        
        
        
    }
    NSLog(@"%.5f", Opacity);
    if (next_iref != nil) {
        //            [gamaFilter setGamma:1+(1-Opacity)*2];
        [stillImageFilter2 setOpacity:Opacity];
    }
    
    
    if (next_iref != nil && Opacity != 0) {
        
        CGImageRef nextimageFilter1 = nil;
        CGImageRef nextimageFilter = nil;
        if (next_iref != nil ) {
            if (self.flagfilter) {
                nextimageFilter = [filter newCGImageByFilteringCGImage:next_iref];
//                nextimageFilter = [levelfilter newCGImageByFilteringCGImage:nextimageFilter1];
                
            }else
                nextimageFilter = next_iref;
                
            
        }
        

        
        CGImageRef quickFilteredImage = [stillImageFilter2 newCGImageByFilteringCGImage:nextimageFilter];
        
        
        int width_next = CGImageGetWidth(nextimageFilter);
        int height_next = CGImageGetHeight(nextimageFilter);
        
        if (next_direction == SLIDE_LEFT) {
            CGContextDrawImage(context, CGRectMake((480-width_next)/2+transitionTimeStep, -(height_next-480)/2, width_next,height_next), quickFilteredImage);
            
        }else if (next_direction == SLIDE_RIGHT)
        {
            CGContextDrawImage(context, CGRectMake((480-width_next)/2-transitionTimeStep, -(height_next-480)/2, width_next,height_next), quickFilteredImage);
            
        }else if (next_direction == SLIDE_UP)
        {
            
            CGContextDrawImage(context, CGRectMake(-(width_next-480)/2, (480-height_next)/2-transitionTimeStep, width_next,height_next), quickFilteredImage);
            
        }else
        {
            CGContextDrawImage(context, CGRectMake(-(width_next-480)/2, (480-height_next)/2+transitionTimeStep, width_next,height_next), quickFilteredImage);
        }
        
        CGImageRelease(quickFilteredImage);
        if (nextimageFilter != nil && self.flagfilter) {
            CGImageRelease(nextimageFilter);
            CGImageRelease(nextimageFilter1);
        }
        
        
    }else
    {
        
    }
    //    GPUImageGammaFilter *gamaFilter = [[GPUImageGammaFilter alloc]init];
    if  (self.flagfilter) {
        CGContextDrawImage(context, CGRectMake(0, 0, 480,480), overlayref);
    }
    
    
    
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
	
    if (self.flagfilter) {
//        CGImageRelease(imageFilter1);
        CGImageRelease(imageFilter);
    }
    
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
	
    return pxbuffer;
}
-(void)failAlert{
    UIAlertView *alert1 = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Export Failed.Try again." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert1 show];
    
}

//- (IBAction)onClickRecordPause:(id)sender {
//    [self presentViewController:self.picker animated:YES completion:^
//     {
//         [self.picker setNeedsStatusBarAppearanceUpdate];
//
//     }];
//
//}



#pragma mark Media item picker delegate methods
- (void) mediaPickerDidCancel: (MPMediaPickerController *) mediaPicker {
    
	[self dismissViewControllerAnimated:YES completion:nil];
    
    
}

- (void) mediaPicker: (MPMediaPickerController *) mediaPicker didPickMediaItems: (MPMediaItemCollection *) mediaItemCollection {
    
	// Dismiss the media item picker.
	[self dismissViewControllerAnimated:YES completion:nil];
    
    MPMediaItem *item=[[mediaItemCollection items] objectAtIndex:0];
    self.selectedSongURL = [item valueForProperty: MPMediaItemPropertyAssetURL];
    NSString* pathaaa = self.selectedSongURL.absoluteString;
    NSLog(@"ID = [%@]",[item valueForProperty:MPMediaItemPropertyPersistentID]);
    NSLog(@"Title = [%@]",[item valueForProperty:MPMediaItemPropertyTitle]);
    NSLog(@"URL = [%@]",[item valueForProperty:MPMediaItemPropertyAssetURL]);
    
    if(![item valueForProperty:MPMediaItemPropertyAssetURL])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"song_unvailable", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    [ProgressHUD show:@"Please wait"];
    [NSThread detachNewThreadSelector:@selector(createVideoWithAudio) toTarget:self withObject:nil];
}
- (NSArray *)getTimes {
    //  First item must be at time 0. All other sounds must be relative to this first sound.
    return [NSArray arrayWithObjects:[NSNumber numberWithInt:0],[NSNumber numberWithInt:10], nil];
}
-(void)createVideo1
{
    [ProgressHUD show:@"Please wait"];
    [self disableAllUI];
    [NSThread detachNewThreadSelector:@selector(createVideoWithAudio) toTarget:self withObject:nil];
}



-(void) createVideoWithAudio
{
    [self RemovePlayer];
    
    exportedVideo = [[NSString alloc] initWithString:[NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"mp4"]]];
    
    
    
    if (self.selectedSongURL != nil || self.recordedSongURL != nil) {
        
        NSString *outPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"mergeaudio.caf"];
        NSURL *outputURL = [NSURL fileURLWithPath:outPath];
        
        if (self.selectedSongURL == nil) {
            outputURL = self.recordedSongURL;
        }else if(self.recordedSongURL == nil)
        {
            outputURL = self.selectedSongURL;
        }else
        {
            NSString *outPath1 = [NSTemporaryDirectory() stringByAppendingPathComponent:@"audio1.caf"];
            NSString *outPath2 = [NSTemporaryDirectory() stringByAppendingPathComponent:@"audio2.caf"];
            
            [PCMMixer convertFile:self.selectedSongURL.path toFile:outPath1];
            
            [PCMMixer convertFile:self.recordedSongURL.path toFile:outPath2];
            
            
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            
            NSString *mixURL = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Mix.caf"];
            
            
            OSStatus status = [PCMMixer mix:[NSURL URLWithString:outPath1] file2:[NSURL URLWithString:outPath2] offset:0 mixfile:outputURL];
            
            
            
            
        }
        
        
        
        NSError * error1 = nil;
        
        AVMutableComposition * composition = [AVMutableComposition composition];
        
        
        AVURLAsset * videoAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:linkVideo] options:nil];
        
        AVAssetTrack * videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        
        AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                    preferredTrackID: kCMPersistentTrackID_Invalid];
        //	CMTime
        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,videoAsset.duration) ofTrack:videoAssetTrack atTime:kCMTimeZero
                                         error:&error1];
        
        
        
        //audio track in the video
        
        NSArray* tempaudio =[videoAsset tracksWithMediaType:AVMediaTypeAudio];
        if ([tempaudio count]> 0 ) {
            AVAssetTrack * audioAssetTrack1 = [ tempaudio objectAtIndex:0];
            
            AVMutableCompositionTrack *compositionAudioTrack1 = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID: kCMPersistentTrackID_Invalid];
            //	CMTime
            [compositionAudioTrack1 insertTimeRange:CMTimeRangeMake(kCMTimeZero,videoAsset.duration) ofTrack:audioAssetTrack1 atTime:kCMTimeZero
                                              error:&error1];
        }
        
        
        
        
        NSLog(@"%@",linkVideo);
        
        NSLog(@"%@",_selectedSongURL);
        
        
        AVURLAsset * urlAsset = [AVURLAsset URLAssetWithURL:outputURL options:nil];
        
        //    urlAsset
        AVAssetTrack * audioAssetTrack = [[urlAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        
        AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                                    preferredTrackID: kCMPersistentTrackID_Invalid];
        
        
        int repeatIndex = 0;
        
        NSError * error = nil;
        
        CMTime lastTime = urlAsset.duration;
        
        //NSMutableIndexSet *timeIntArray = [[NSMutableIndexSet alloc]init ];
        
        NSMutableArray *timeArray = [[NSMutableArray alloc]init];
        
        if ((int)(CMTimeGetSeconds(videoAsset.duration)) > (int)(CMTimeGetSeconds(urlAsset.duration))
            ) {
            if ((int)(CMTimeGetSeconds(videoAsset.duration)) % (int)(CMTimeGetSeconds(urlAsset.duration)) ==0) {
                repeatIndex = ((int)(CMTimeGetSeconds(videoAsset.duration)) / (int)(CMTimeGetSeconds(urlAsset.duration)));
                
                for (int i=0; i<repeatIndex; i++) {
                    [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,urlAsset.duration) ofTrack:audioAssetTrack atTime:kCMTimeZero error:&error];
                }
                
            }
            else{
                repeatIndex = ((int)(CMTimeGetSeconds(videoAsset.duration)) / (int)(CMTimeGetSeconds(urlAsset.duration)))+1;
                
                
                int countTime = 0;
                for (int i=0; i<repeatIndex; i++) {
                    
                    
                    [timeArray addObject:[NSString stringWithFormat:@"%d",(int)(CMTimeGetSeconds(lastTime))]];
                    
                    countTime = countTime + (int)(CMTimeGetSeconds(lastTime));
                    
                    
                    
                    
                    if ((int)(CMTimeGetSeconds(videoAsset.duration))-countTime > (int)(CMTimeGetSeconds(urlAsset.duration))) {
                        lastTime = urlAsset.duration;
                    }
                    else{
                        lastTime = CMTimeMake((int)(CMTimeGetSeconds(videoAsset.duration))-countTime, 1);
                    }
                    
                    
                }
                for (int i=[timeArray count]-1; i>=0; i--) {
                    
                    CMTime makeTime = CMTimeMake([[timeArray objectAtIndex:i] intValue], 1);
                    [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,makeTime) ofTrack:audioAssetTrack atTime:kCMTimeZero error:&error];
                }
            }
        }
        else {
            repeatIndex = 1;
            [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,videoAsset.duration) ofTrack:audioAssetTrack atTime:kCMTimeZero error:&error];
        }
        
        AVAssetExportSession* assetExport = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
        //assetExport.videoComposition = compositionVideoTrack;
        
        assetExport.outputFileType = AVFileTypeMPEG4;
        assetExport.outputURL = [NSURL fileURLWithPath:exportedVideo];
        
        [assetExport exportAsynchronouslyWithCompletionHandler:
         ^(void ) {
             switch (assetExport.status)
             {
                 case AVAssetExportSessionStatusCompleted:
                     //                export complete
                     NSLog(@"Export Complete");
                     
                     [self performSelectorOnMainThread:@selector(addMusicSuccessfully) withObject:nil waitUntilDone:YES ];
                     
                     break;
                 case AVAssetExportSessionStatusFailed:
                     
                     
                     
                     [self performSelectorOnMainThread:@selector(failAlert) withObject:nil waitUntilDone:NO ];
                     
                     
                     
                     NSLog(@"Export Failed");
                     NSLog(@"ExportSessionError: %@", [assetExport.error localizedDescription]);
                     // [pool release];
                     //                export error (see exportSession.error)
                     break;
                 case AVAssetExportSessionStatusCancelled:
                     //                export cancelled
                     break;
             }
         }];
        
        
        
        
        
    }
    else{
        
        
        [self performSelectorOnMainThread:@selector(addMusicSuccessfully) withObject:nil waitUntilDone:YES ];
    }
}
-(void)addMusicSuccessfully{
    
    [ProgressHUD dismiss];
    [self enableAllUI];
    
    
    [self.mPlayer setVolume:1.0];
    [self setPlayFile:exportedVideo];
    [self StartPlayer];
    
    //
    //  UISaveVideoAtPathToSavedPhotosAlbum(exportedVideo, self,  @selector(video:didFinishSavingWithError:contextInfo:), nil);
    
}

///video play

- (void) RemovePlayer {
    if (self.mPlayer) {
        [[NSNotificationCenter defaultCenter] removeObserver: self name:AVPlayerItemDidPlayToEndTimeNotification object:self.mPlayer.currentItem];
        [self.mPlayer pause];
        self.mPlayer = nil;
    }
    
    if (self.mPlayerLayer) {
        [self.mPlayerLayer removeFromSuperlayer];
        self.mPlayerLayer = nil;
    }
    
    if (m_playtimer) {
        [m_playtimer invalidate];
        m_playtimer = nil;
    }
    
}

- (void) removeFile:(NSURL *)fileURL
{
    NSString *filePath = [fileURL path];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *error;
        if ([fileManager removeItemAtPath:filePath error:&error] == NO) {
            
        }
    }
}

- (void) StartPlayer{
    NSLog(@"Start player");
    
    
    [self.mPlayer play];
    playing = true;
    
    
    self.mPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(continueBackground:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.mPlayerItem];
    
    
}
- (void) continueBackground:(NSNotification*)notification {
    AVPlayerItem *p = notification.object;
    [p seekToTime:kCMTimeZero];
    
}
- (void) setPlayFile:(NSString *)filepath {
    
    
    NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:filepath];
    
    self.mPlayerItem = [AVPlayerItem playerItemWithURL:outputURL];
    if (self.mPlayer) {
        [self RemovePlayer];
    }
    
    AVAsset *asset = self.mPlayerItem.asset;
    NSArray *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
    
    // Mute all the audio tracks
    NSMutableArray *allAudioParams = [NSMutableArray array];
    for (AVAssetTrack *track in audioTracks) {
        AVMutableAudioMixInputParameters *audioInputParams =    [AVMutableAudioMixInputParameters audioMixInputParameters];
        [audioInputParams setVolume:1.0 atTime:kCMTimeZero];
        [audioInputParams setTrackID:[track trackID]];
        [allAudioParams addObject:audioInputParams];
    }
    AVMutableAudioMix *audioZeroMix = [AVMutableAudioMix audioMix];
    [audioZeroMix setInputParameters:allAudioParams];
    
    [self.mPlayerItem setAudioMix:audioZeroMix];
    
    self.mPlayer = [AVPlayer playerWithPlayerItem:self.mPlayerItem] ;
    
    self.mPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.mPlayer];
    
    self.mPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    
    [self.m_previewVideo.layer addSublayer:self.mPlayerLayer];
    
    [self SetPlayerFrame];
    
    duration = (float)CMTimeGetSeconds([asset duration]);
    //    CMTime duration = [self.mPlayerItem duration];
    //    m_totalframe = duration.value / 20 + 1;
    //    NSLog(@"total value is %d", duration.value);
    
}
- (void)SetPlayerFrame {
    if (self.mPlayerLayer == nil)
        return;
    
    
    [self.mPlayerLayer setFrame:CGRectMake(0, 0, 320, 320)];
    
    NSLog(@"layer %f %f %f %f", self.mPlayerLayer.frame.origin.x, self.mPlayerLayer.frame.origin.y, self.mPlayerLayer.frame.size.width, self.mPlayerLayer.frame.size.height);
}

-(IBAction)onClickRecordPause{
    
    
    
    NSArray *dirPaths;
    NSString *docsDir;
    
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = [dirPaths objectAtIndex:0];
    NSString *soundFilePath = [docsDir stringByAppendingPathComponent:@"sound%d.caf"];
    [self.voiceHud setHidden:NO];
    [self.voiceHud startForFilePath:soundFilePath duration:duration];
    
    [self.mPlayer seekToTime:kCMTimeZero];
    [self.mPlayer setVolume:0.0];
    [self disableAllUI];
}


#pragma mark - POVoiceHUD Delegate

- (void)POVoiceHUD:(POVoiceHUD *)voiceHUD voiceRecorded:(NSString *)recordPath length:(float)recordLength {
    
    
    NSURL *soundFileURL = [NSURL fileURLWithPath:recordPath];
    
    [self.voiceHud setHidden:YES];
    self.recordedSongURL = soundFileURL;
    [self createVideo1];
    
    [self enableAllUI];
    
    NSLog(@"Sound recorded with file %@ for %.2f seconds", [recordPath lastPathComponent], recordLength);
}

- (void)voiceRecordCancelledByUser:(POVoiceHUD *)voiceHUD {
    NSLog(@"Voice recording cancelled for HUD: %@", voiceHUD);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"gorecord"]){
        [self RemovePlayer];
        AudioRecordViewController  *controller = segue.destinationViewController;
        
        controller.parent = self;
    }
}

- (void)scrollMenu:(ACPScrollMenu *)menu didSelectIndex:(NSInteger)selectedIndex
{
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"enjoytime" ofType:@"m4a"];
    
    switch (selectedIndex) {
        case 0:
            filePath = [[NSBundle mainBundle] pathForResource:@"funnysnowman" ofType:@"m4a"];
            
            break;
        case 1:
            filePath = [[NSBundle mainBundle] pathForResource:@"enjoytime" ofType:@"m4a"];
            
            break;
            
        case 2:
            filePath = [[NSBundle mainBundle] pathForResource:@"mysterytree" ofType:@"m4a"];
            
            break;
            
        case 3:
            filePath = [[NSBundle mainBundle] pathForResource:@"suddenlymeet" ofType:@"m4a"];
            
            break;
            
        case 4:
            filePath = [[NSBundle mainBundle] pathForResource:@"youisyou" ofType:@"m4a"];
            
            break;
            
        case 5:
            filePath = [[NSBundle mainBundle] pathForResource:@"unipaste" ofType:@"m4a"];
            
            break;
            
        default:
            break;
    }
    
    NSURL *soundFileURL = [NSURL fileURLWithPath:filePath];
    
    [self.voiceHud setHidden:YES];
    self.selectedSongURL = soundFileURL;
    [self createVideo1];
    
    
}

@end
