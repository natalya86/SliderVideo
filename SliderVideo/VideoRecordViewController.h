//
//  VideoRecordViewController.h
//  SliderVideo
//
//  Created by admin on 7/14/14.
//  Copyright (c) 2014 tinystone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MDRadialProgressView.h"
#import "MDRadialProgressTheme.h"
#import "MDRadialProgressLabel.h"
#import "KZCameraView.h"

#import "GPUImage.h"
#import "GPUImageMovie.h"

@interface VideoRecordViewController: UIViewController
{
    

    NSString* filterVideo;
    NSString* videopath;
    
    GPUImageMovie *movieFile;
    GPUImageOutput<GPUImageInput> *filter;
    
    GPUImageLevelsFilter *filter1;
    
    GPUImageMovieWriter *movieWriter;
    
}

@property (nonatomic, strong) KZCameraView *cam;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *nextitem;
@end
