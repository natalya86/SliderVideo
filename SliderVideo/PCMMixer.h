//
//  PCMMixer.h
//
//  Created by Moses DeJong on 3/25/09.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioFile.h>
#include <AudioToolbox/AudioToolbox.h>

// Returned as the value of the OSStatus argument to mix when the sound samples
// values would clip when mixed together. If a mix would clip then the output
// file is not generated.

#define OSSTATUS_MIX_WOULD_CLIP 8888


@interface PCMMixer : NSObject {

}
+ (OSStatus) mix:(NSURL*)url1 file2:(NSURL*)url2 offset:(int)offset mixfile:(NSURL*)mixURL;
+ (OSStatus) mixFiles:(NSArray*)files atTimes:(NSArray*)times toMixfile:(NSString*)mixfile;

+ (BOOL)convertFile:(NSString*)fileIn toFile:(NSString*)fileOut;



typedef struct MyAudioConverterSettings
{
    AudioStreamBasicDescription outputFormat; // output file's data stream description
    
    ExtAudioFileRef					inputFile; // reference to your input file
    AudioFileID					outputFile; // reference to your output file
    
} MyAudioConverterSettings;

@end
