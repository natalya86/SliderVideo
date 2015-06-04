//
//  AudioRecordViewController.m
//  SliderVideo
//
//  Created by admin on 7/10/14.
//  Copyright (c) 2014 tinystone. All rights reserved.
//

#import "AudioRecordViewController.h"

@interface AudioRecordViewController ()

@end

@implementation AudioRecordViewController

@synthesize parent,playbtn;

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

-(IBAction)clickDone:(id)sender
{
    
    NSArray *dirPaths;
    NSString *docsDir;
    
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = [dirPaths objectAtIndex:0];
    NSString *soundFilePath = [docsDir stringByAppendingPathComponent:@"sound%d.caf"];
    
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    
    
    self.parent.selectedSongURL = soundFileURL;
    [self.parent createVideo1];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)onClickPlay{
    NSError *error;
    
    NSArray *dirPaths;
    NSString *docsDir;
    
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = [dirPaths objectAtIndex:0];
    NSString *soundFilePath = [docsDir stringByAppendingPathComponent:@"sound%d.caf"];
    
    
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    
    AVAudioPlayer * audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:&error];
    
    
	audioPlayer.delegate = self;
	[audioPlayer prepareToPlay];
    [audioPlayer setVolume:1.0f];
    
    [audioPlayer play];
    
    
}


-(IBAction)onClickRecordPause{
    
//   
//    
//    NSArray *dirPaths;
//    NSString *docsDir;
//    
//    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    docsDir = [dirPaths objectAtIndex:0];
//    NSString *soundFilePath = [docsDir stringByAppendingPathComponent:@"sound%d.caf"];
//    
//   [self.voiceHud startForFilePath:soundFilePath];
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.voiceHud = [[POVoiceHUD alloc] initWithParentView:self.view];
    self.voiceHud.title = @"Speak Now";
    
    [self.voiceHud setDelegate:self];
    [self.view addSubview:self.voiceHud];
    
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - POVoiceHUD Delegate

- (void)POVoiceHUD:(POVoiceHUD *)voiceHUD voiceRecorded:(NSString *)recordPath length:(float)recordLength {
    NSLog(@"Sound recorded with file %@ for %.2f seconds", [recordPath lastPathComponent], recordLength);
}

- (void)voiceRecordCancelledByUser:(POVoiceHUD *)voiceHUD {
    NSLog(@"Voice recording cancelled for HUD: %@", voiceHUD);
}


@end
