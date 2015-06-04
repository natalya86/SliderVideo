

#import "POVoiceHUD.h"

@implementation POVoiceHUD

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.contentMode = UIViewContentModeRedraw;

		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];

		self.alpha = 0.0f;
        
        hudRect = CGRectMake(self.center.x - (HUD_SIZE / 2), self.center.y - (HUD_SIZE / 2), HUD_SIZE, HUD_SIZE);
        int x = (frame.size.width - HUD_SIZE) / 2;
//        btnCancel = [[UIButton alloc] initWithFrame:CGRectMake(x, hudRect.origin.y + HUD_SIZE - CANCEL_BUTTON_HEIGHT, HUD_SIZE, CANCEL_BUTTON_HEIGHT)];
//        [btnCancel setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
//        [btnCancel addTarget:self action:@selector(cancelled:) forControlEvents:UIControlEventTouchUpInside];
//        [self addSubview:btnCancel];
        
        imgMicrophone = [UIImage imageNamed:@"microphone"];
 
        soundMeter  = 0;
        
    }
    
    return self;
}

- (id)initWithParentView:(UIView *)view {
    return [self initWithFrame:view.bounds];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self commitRecording];
}

- (void)startForFilePath:(NSString *)filePath duration:(float)duration{
    recordTime = 0;
    
    self.alpha = 1.0f;
    [self setNeedsDisplay];

	AVAudioSession *audioSession = [AVAudioSession sharedInstance];
	NSError *err = nil;
	[audioSession setCategory :AVAudioSessionCategoryPlayAndRecord error:&err];
	if(err){
        NSLog(@"audioSession: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
        return;
	}
	[audioSession setActive:YES error:&err];
	err = nil;
	if(err){
        NSLog(@"audioSession: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
        return;
	}
	
	recordSetting = [[NSMutableDictionary alloc] init];
	
	[recordSetting setValue :[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];
    [recordSetting setValue :[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [recordSetting setValue :[NSNumber numberWithBool:YES] forKey:AVLinearPCMIsFloatKey];
    [recordSetting setValue :[NSNumber numberWithInt:AVAudioQualityMax] forKey:AVEncoderAudioQualityKey];
    [recordSetting setValue :[NSNumber numberWithInt: kAudioFormatAppleIMA4]  forKey:AVFormatIDKey];
	
	// if you are using kAudioFormatLinearPCM format, activate these settings
	//[recordSetting setValue :[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
	//[recordSetting setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
	//[recordSetting setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
	
    NSLog(@"Recording at: %@", filePath);
	recorderFilePath = filePath;
	
	NSURL *url = [NSURL fileURLWithPath:recorderFilePath];
	
	err = nil;
	
	NSData *audioData = [NSData dataWithContentsOfFile:[url path] options: 0 error:&err];
	if(audioData)
	{
		NSFileManager *fm = [NSFileManager defaultManager];
		[fm removeItemAtPath:[url path] error:&err];
	}
	
	err = nil;
	recorder = [[ AVAudioRecorder alloc] initWithURL:url settings:recordSetting error:&err];
	if(!recorder){
        NSLog(@"recorder: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
        UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle: @"Warning"
								   message: [err localizedDescription]
								  delegate: nil
						 cancelButtonTitle:@"OK"
						 otherButtonTitles:nil];
        [alert show];
        return;
	}
	
	[recorder setDelegate:self];
	[recorder prepareToRecord];
	recorder.meteringEnabled = YES;
	
	BOOL audioHWAvailable = audioSession.inputIsAvailable;
	if (! audioHWAvailable) {
        UIAlertView *cantRecordAlert =
        [[UIAlertView alloc] initWithTitle: @"Warning"
								   message: @"Audio input hardware not available"
								  delegate: nil
						 cancelButtonTitle:@"OK"
						 otherButtonTitles:nil];
        [cantRecordAlert show];
        return;
	}
	
	[recorder recordForDuration:(NSTimeInterval) duration];
	
	timer = [NSTimer scheduledTimerWithTimeInterval:WAVE_UPDATE_FREQUENCY target:self selector:@selector(updateMeters) userInfo:nil repeats:YES];
}

- (void)updateMeters {
    [recorder updateMeters];

    NSLog(@"meter:%5f", [recorder averagePowerForChannel:0]);
   
    
    recordTime += WAVE_UPDATE_FREQUENCY;
    [self addSoundMeterItem:[recorder averagePowerForChannel:0]];
    
}
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    [timer invalidate];
    
    if ([self.delegate respondsToSelector:@selector(POVoiceHUD:voiceRecorded:length:)]) {
        [self.delegate POVoiceHUD:self voiceRecorded:recorderFilePath length:recordTime];
    }
}
- (void)cancelRecording {
    if ([self.delegate respondsToSelector:@selector(voiceRecordCancelledByUser:)]) {
        [self.delegate voiceRecordCancelledByUser:self];
    }
    
    [recorder stop];
}

- (void)commitRecording {
    [recorder stop];
    [timer invalidate];
//    
//    if ([self.delegate respondsToSelector:@selector(POVoiceHUD:voiceRecorded:length:)]) {
//        [self.delegate POVoiceHUD:self voiceRecorded:recorderFilePath length:recordTime];
//    }
//    
    self.alpha = 0.0;
    [self setNeedsDisplay];
}

- (void)cancelled:(id)sender {
    self.alpha = 0.0;
    [self setNeedsDisplay];
    
    [timer invalidate];
    [self cancelRecording];
}

- (void)setCancelButtonTitle:(NSString *)title {
    btnCancel.titleLabel.text = title;
}

#pragma mark - Sound meter operations



- (void)addSoundMeterItem:(int)lastValue {
    
    soundMeter = lastValue;
    
    [self setNeedsDisplay];
}

#pragma mark - Drawing operations

- (void)drawRect:(CGRect)rect {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
   
    UIColor *fillColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
    UIColor *gradientColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
    
    
    
    NSArray *gradientColors = [NSArray arrayWithObjects:
                               (id)fillColor.CGColor,
                               (id)gradientColor.CGColor, nil];
    CGFloat gradientLocations[] = {0, 1};
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)gradientColors, gradientLocations);
    
    UIBezierPath *border = [UIBezierPath bezierPathWithRoundedRect:hudRect cornerRadius:0];
    CGContextSaveGState(context);
    [border addClip];
    CGContextDrawRadialGradient(context, gradient,
                                CGPointMake(hudRect.origin.x+HUD_SIZE/2, 120), 10,
                                CGPointMake(hudRect.origin.x+HUD_SIZE/2, 195), 215,
                                kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
    
    CGContextRestoreGState(context);
    
    
    
    // Draw sound meter wave
    
    [[UIColor colorWithRed:0.32 green:0.19 blue:0.36 alpha:1.0] set];
    
    CGContextSetLineWidth(context, 2.0);
    CGContextSetLineJoin(context, kCGLineJoinRound);

    for(CGFloat x = 5 - 1; x >= 0; x--)
    {
        if (soundMeter > -40) {
            CGContextMoveToPoint(context, hudRect.origin.x +hudRect.size.width/2 + 5, hudRect.origin.y +hudRect.size.height - 20);
            CGContextAddLineToPoint(context, hudRect.origin.x +hudRect.size.width - 25, hudRect.origin.y +hudRect.size.height - 20);
        }
        
        if (soundMeter > -35) {
            CGContextMoveToPoint(context, hudRect.origin.x +hudRect.size.width/2 + 5, hudRect.origin.y +hudRect.size.height - 26);
            CGContextAddLineToPoint(context, hudRect.origin.x +hudRect.size.width - 20, hudRect.origin.y +hudRect.size.height - 26);
        }
        
        if (soundMeter > -25) {
            CGContextMoveToPoint(context, hudRect.origin.x +hudRect.size.width/2 + 5, hudRect.origin.y +hudRect.size.height - 32);
            CGContextAddLineToPoint(context, hudRect.origin.x +hudRect.size.width - 15, hudRect.origin.y +hudRect.size.height - 32);
        }
        
        if (soundMeter > -15) {
            CGContextMoveToPoint(context, hudRect.origin.x +hudRect.size.width/2 + 5, hudRect.origin.y +hudRect.size.height - 38);
            CGContextAddLineToPoint(context, hudRect.origin.x +hudRect.size.width - 10, hudRect.origin.y +hudRect.size.height - 38);
        }
        
        if (soundMeter > -10) {
            CGContextMoveToPoint(context, hudRect.origin.x +hudRect.size.width/2 + 5, hudRect.origin.y +hudRect.size.height - 44);
            CGContextAddLineToPoint(context, hudRect.origin.x +hudRect.size.width - 5, hudRect.origin.y +hudRect.size.height - 44);
        }
        
        
    }
    
    CGContextStrokePath(context);

//    // Draw title
//    [color setFill];
//    [self.title drawInRect:CGRectInset(hudRect, 0, 25) withFont:[UIFont systemFontOfSize:42.0] lineBreakMode:NSLineBreakByWordWrapping alignment:NSTextAlignmentCenter];

    [imgMicrophone drawAtPoint:CGPointMake(hudRect.origin.x + hudRect.size.width/2 - imgMicrophone.size.width, hudRect.origin.y + hudRect.size.height/2 - imgMicrophone.size.height/2)];
    
//    [[UIColor colorWithWhite:0.8 alpha:1.0] setFill];
//    UIBezierPath *line = [UIBezierPath bezierPath];
//    [line moveToPoint:CGPointMake(hudRect.origin.x, hudRect.origin.y + HUD_SIZE - CANCEL_BUTTON_HEIGHT)];
//    [line addLineToPoint:CGPointMake(hudRect.origin.x + HUD_SIZE, hudRect.origin.y + HUD_SIZE - CANCEL_BUTTON_HEIGHT)];
//    [line setLineWidth:3.0];
//    [line stroke];
}

@end
