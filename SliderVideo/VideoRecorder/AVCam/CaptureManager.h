

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class AVCamRecorder;
@protocol CaptureManagerDelegate;

@interface CaptureManager : NSObject {
}

@property (nonatomic,strong) AVCaptureSession *session;
@property (nonatomic,assign) AVCaptureVideoOrientation orientation;
@property (nonatomic,strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic,strong) AVCaptureDeviceInput *audioInput;
@property (nonatomic,strong) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic,strong) AVCamRecorder *recorder;
@property (nonatomic,assign) id deviceConnectedObserver;
@property (nonatomic,assign) id deviceDisconnectedObserver;
@property (nonatomic,assign) UIBackgroundTaskIdentifier backgroundRecordingID;
@property (nonatomic,assign) id <CaptureManagerDelegate> delegate;
@property (nonatomic,strong) NSMutableArray *assets;
@property (nonatomic,assign) NSTimer *exportProgressBarTimer;
@property (nonatomic,strong) AVAssetExportSession *exportSession;

- (BOOL) setupSession;
- (void) startRecording;
- (void) stopRecording;
- (void) saveVideoWithCompletionBlock:(void(^)(BOOL success))completion;
- (NSUInteger) cameraCount;
- (NSUInteger) micCount;
- (void) autoFocusAtPoint:(CGPoint)point;
- (void) continuousFocusAtPoint:(CGPoint)point;
- (void) switchCamera;
- (void) deleteLastAsset;

@end

// These delegate methods can be called on any arbitrary thread. If the delegate does something with the UI when called, make sure to send it to the main thread.
@protocol CaptureManagerDelegate <NSObject>
@optional

- (void) removeTimeFromDuration:(float)removeTime;

- (void) updateProgress;
- (void) removeProgress;

- (void) captureManager:(CaptureManager *)captureManager didFailWithError:(NSError *)error;
- (void) captureManagerRecordingBegan:(CaptureManager *)captureManager;
- (void) captureManagerRecordingFinished:(CaptureManager *)captureManager;
- (void) captureManagerStillImageCaptured:(CaptureManager *)captureManager;
- (void) captureManagerDeviceConfigurationChanged:(CaptureManager *)captureManager;
@end
