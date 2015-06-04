//
//  VideoSelectViewController.h
//  SliderVideo
//
//  Created by admin on 7/25/14.
//  Copyright (c) 2014 tinystone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPUImage.h"
#import "GPUImageMovie.h"


@interface VideoSelectViewController : UIViewController<UIImagePickerControllerDelegate , UINavigationControllerDelegate>
{
    NSString* filterVideo;
    NSString* videopath;
    NSURL *videoUrl;
    AVAssetExportSession *exporter;
    GPUImageMovie *movieFile;
    GPUImageOutput<GPUImageInput> *filter;
//    GPUImageLevelsFilter *filter1;
    
    GPUImageMovieWriter *movieWriter;
}
@property (nonatomic,retain) IBOutlet UIButton* checkfilter;
@property (retain, nonatomic) IBOutlet UIButton* selbtn;

@property (nonatomic, retain)IBOutlet  UIBarButtonItem* m_itemnext;
@property (nonatomic, retain)IBOutlet  UIBarButtonItem* m_itemback;

@end
