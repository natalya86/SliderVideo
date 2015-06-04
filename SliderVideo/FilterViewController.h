//
//  FilterViewController.h
//  SliderVideo
//
//  Created by admin on 7/2/14.
//  Copyright (c) 2014 tinystone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "GPUImage.h"
#import "GPUImageMovie.h"
#import "AppDelegate.h"
#import <MediaPlayer/MPMediaPickerController.h>

#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <MediaPlayer/MediaPlayer.h>

#import "POVoiceHUD.h"
#import "ACPScrollMenu.h"

@interface FilterViewController : UIViewController<MPMediaPickerControllerDelegate,POVoiceHUDDelegate, AVAudioPlayerDelegate,ACPScrollDelegate>
{
    
    int progressCount;
    int captureindex;
    int countImg;
    
    int filtertype;
    NSTimer *m_playtimer;
    
    
    CGImageRef overlayref;
    int direction;
    int next_direction;
    int transitionTimeStep;
    
    float duration;
    BOOL flag_export;
    BOOL playing;
    
    
}
@property (readwrite)BOOL flagfilter;
@property (nonatomic, strong)  MPMediaPickerController *picker;
@property (nonatomic, strong)	NSURL					*selectedSongURL;

@property (nonatomic, strong)	NSURL					*recordedSongURL;
@property (nonatomic,retain)  NSString *linkVideo; //link video without audio
@property (nonatomic,retain)  NSString *exportedVideo;

@property (nonatomic, strong) NSMutableArray *mediaArray;
@property (nonatomic,readwrite)int shareFlag;

@property (nonatomic, retain) POVoiceHUD *voiceHud;

@property (weak, nonatomic) IBOutlet ACPScrollMenu *scrollMenu;
@property (nonatomic, retain) IBOutlet  UIImageView *m_previewVideo;    //video play view

@property (nonatomic, retain) AVPlayerItem *mPlayerItem;
@property (nonatomic, retain) AVPlayerLayer *mPlayerLayer;
@property (nonatomic, retain) AVPlayer *mPlayer;

@property (nonatomic, retain)IBOutlet  UIButton* m_addrecord;
@property (nonatomic, retain)IBOutlet  UIBarButtonItem* m_itemnext;
@property (nonatomic, retain)IBOutlet  UIBarButtonItem* m_itemback;
-(void)createVideo1;
@end
