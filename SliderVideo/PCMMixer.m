//
//  PCMMixer.m
//
//  Created by Moses DeJong on 3/25/09.
//

#import "PCMMixer.h"

#import <unistd.h>

// Mix sample data from two buffers, if clipping is detected
// then we have to exit the mix operation.

static
inline
BOOL mix_buffers(const int16_t *buffer1,
				 const int16_t *buffer2,
				 int16_t *mixbuffer,
				 int mixbufferNumSamples)
{
	BOOL clipping = FALSE;

	for (int i = 0 ; i < mixbufferNumSamples; i++) {
		int32_t s1 = buffer1[i];
		int32_t s2 = buffer2[i];
		int32_t mixed = s1 + s2;

//    Brick wall limiter
    if (mixed < -32768)
      mixed = -32768;
    else if (mixed > 32767)
      mixed = 32767;
    mixbuffer[i] = (int16_t) mixed;

//    Clipping detection
//		if ((mixed < -32768) || (mixed > 32767)) {
//			clipping = TRUE;
//			break;
//		} else {
//			mixbuffer[i] = (int16_t) mixed;
//		}
	}

	return clipping;
}

@implementation PCMMixer

+ (void) _setDefaultAudioFormatFlags:(AudioStreamBasicDescription*)audioFormatPtr
						 numChannels:(NSUInteger)numChannels
{
	bzero(audioFormatPtr, sizeof(AudioStreamBasicDescription));

	audioFormatPtr->mFormatID = kAudioFormatLinearPCM;
	audioFormatPtr->mSampleRate = 44100.0;
	audioFormatPtr->mChannelsPerFrame = numChannels;
	audioFormatPtr->mBytesPerPacket = 2 * numChannels;
	audioFormatPtr->mFramesPerPacket = 1;
	audioFormatPtr->mBytesPerFrame = 2 * numChannels;
	audioFormatPtr->mBitsPerChannel = 16;
	audioFormatPtr->mFormatFlags = kAudioFormatFlagsNativeEndian |
	kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
}


+ (BOOL)convertFile:(NSString*)fileIn toFile:(NSString*)fileOut {
    MyAudioConverterSettings audioConverterSettings = {0};
	// open the input with ExtAudioFile
	CFURLRef inputFileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (__bridge CFStringRef)fileIn, kCFURLPOSIXPathStyle, false);
	CheckResult(ExtAudioFileOpenURL(inputFileURL,
                                    &audioConverterSettings.inputFile),
                "ExtAudioFileOpenURL failed");
    CFRelease(inputFileURL);
    
    if ([fileOut rangeOfString:@".aiff"].location != NSNotFound) {
        // define the ouput format. AudioConverter requires that one of the data formats be LPCM
        audioConverterSettings.outputFormat.mSampleRate = 44100.0;
        audioConverterSettings.outputFormat.mFormatID = kAudioFormatLinearPCM;
        audioConverterSettings.outputFormat.mFormatFlags = kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
        audioConverterSettings.outputFormat.mBytesPerPacket = 4;
        audioConverterSettings.outputFormat.mFramesPerPacket = 1;
        audioConverterSettings.outputFormat.mBytesPerFrame = 4;
        audioConverterSettings.outputFormat.mChannelsPerFrame = 2;
        audioConverterSettings.outputFormat.mBitsPerChannel = 16;
        
        // create output file
        CFURLRef outputFileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (__bridge CFStringRef)fileOut, kCFURLPOSIXPathStyle, false);
        CheckResult (AudioFileCreateWithURL(outputFileURL, kAudioFileAIFFType, &audioConverterSettings.outputFormat, kAudioFileFlags_EraseFile, &audioConverterSettings.outputFile),
                     "AudioFileCreateWithURL failed");
        CFRelease(outputFileURL);
    } else if ([fileOut rangeOfString:@".caf"].location != NSNotFound) {
        // define the ouput format. AudioConverter requires that one of the data formats be LPCM
        audioConverterSettings.outputFormat.mSampleRate = 44100.0;
        audioConverterSettings.outputFormat.mFormatID = kAudioFormatLinearPCM;
        audioConverterSettings.outputFormat.mFormatFlags =  kAudioFormatFlagsCanonical;
        audioConverterSettings.outputFormat.mBytesPerPacket = 4;
        audioConverterSettings.outputFormat.mFramesPerPacket = 1;
        audioConverterSettings.outputFormat.mBytesPerFrame = 4;
        audioConverterSettings.outputFormat.mChannelsPerFrame = 2;
        audioConverterSettings.outputFormat.mBitsPerChannel = 16;
        
        // create output file
        CFURLRef outputFileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (__bridge CFStringRef)fileOut, kCFURLPOSIXPathStyle, false);
        CheckResult (AudioFileCreateWithURL(outputFileURL, kAudioFileCAFType, &audioConverterSettings.outputFormat, kAudioFileFlags_EraseFile, &audioConverterSettings.outputFile),
                     "AudioFileCreateWithURL failed");
        CFRelease(outputFileURL);
    }
	
	// set the PCM format as the client format on the input ext audio file
	CheckResult(ExtAudioFileSetProperty(audioConverterSettings.inputFile,
                                        kExtAudioFileProperty_ClientDataFormat,
                                        sizeof (AudioStreamBasicDescription),
                                        &audioConverterSettings.outputFormat),
                "Couldn't set client data format on input ext file");
	
	fprintf(stdout, "Converting...\n");
	Convert(&audioConverterSettings);
	
cleanup:
	// AudioFileClose(audioConverterSettings.inputFile);
	ExtAudioFileDispose(audioConverterSettings.inputFile);
	AudioFileClose(audioConverterSettings.outputFile);
    return YES;
}
+ (OSStatus) mix:(NSURL*)url1 file2:(NSURL*)url2 offset:(int)offset mixfile:(NSURL*)mixURL
{
	OSStatus status, close_status;

    

	AudioFileID inAudioFile1 = NULL;
	AudioFileID inAudioFile2 = NULL;
	AudioFileID mixAudioFile = NULL;

#ifndef TARGET_OS_IPHONE
	// Why is this constant missing under Mac OS X?
# define kAudioFileReadPermission fsRdPerm
#endif

#define BUFFER_SIZE 1024
	char *buffer1 = NULL;
	char *buffer2 = NULL;
	char *mixbuffer = NULL;

	status = AudioFileOpenURL((__bridge CFURLRef)url1, kAudioFileReadPermission, 0, &inAudioFile1);
    if (status)
	{
		goto reterr;
	}

	status = AudioFileOpenURL((__bridge CFURLRef)url2, kAudioFileReadPermission, 0, &inAudioFile2);
    if (status)
	{
		goto reterr;
	}

	// Verify that file contains pcm data at 44 kHz

    AudioStreamBasicDescription inputDataFormat;
	UInt32 propSize = sizeof(inputDataFormat);

	bzero(&inputDataFormat, sizeof(inputDataFormat));
    status = AudioFileGetProperty(inAudioFile1, kAudioFilePropertyDataFormat,
								  &propSize, &inputDataFormat);

    if (status)
	{
		goto reterr;
	}

	if ((inputDataFormat.mFormatID == kAudioFormatLinearPCM) &&
		(inputDataFormat.mSampleRate == 44100.0) &&
		(inputDataFormat.mChannelsPerFrame == 2) &&
		(inputDataFormat.mChannelsPerFrame == 2) &&
		(inputDataFormat.mBitsPerChannel == 16) &&
		(inputDataFormat.mFormatFlags == (kAudioFormatFlagsNativeEndian |
										  kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger))
		) {
		// no-op when the expected data format is found
	} else {
		status = kAudioFileUnsupportedFileTypeError;
		goto reterr;
	}

	// Do the same for file2

	propSize = sizeof(inputDataFormat);

	bzero(&inputDataFormat, sizeof(inputDataFormat));
    status = AudioFileGetProperty(inAudioFile2, kAudioFilePropertyDataFormat,
								  &propSize, &inputDataFormat);

    if (status)
	{
		goto reterr;
	}

	if ((inputDataFormat.mFormatID == kAudioFormatLinearPCM) &&
		(inputDataFormat.mSampleRate == 44100.0) &&
		(inputDataFormat.mChannelsPerFrame == 2) &&
		(inputDataFormat.mChannelsPerFrame == 2) &&
		(inputDataFormat.mBitsPerChannel == 16) &&
		(inputDataFormat.mFormatFlags == (kAudioFormatFlagsNativeEndian |
										  kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger))
		) {
		// no-op when the expected data format is found
	} else {
		status = kAudioFileUnsupportedFileTypeError;
		goto reterr;
	}

	// Both input files validated, open output (mix) file

	[self _setDefaultAudioFormatFlags:&inputDataFormat numChannels:2];

	status = AudioFileCreateWithURL((__bridge CFURLRef)mixURL, kAudioFileCAFType, &inputDataFormat,
									kAudioFileFlags_EraseFile, &mixAudioFile);
    if (status)
	{
		goto reterr;
	}

	// Read buffer of data from each file

	buffer1 = malloc(BUFFER_SIZE);
	assert(buffer1);
	buffer2 = malloc(BUFFER_SIZE);
	assert(buffer2);
	mixbuffer = malloc(BUFFER_SIZE);
	assert(mixbuffer);

	SInt64 packetNum1 = 0;
	SInt64 packetNum2 = 0;
	SInt64 mixpacketNum = 0;

	while (TRUE) {
		// Read a chunk of input

		UInt32 bytesRead1 = 0;
    UInt32 bytesRead2 = 0;
    UInt32 numPackets1 = 0;
    UInt32 numPackets2 = 0;

		numPackets1 = BUFFER_SIZE / inputDataFormat.mBytesPerPacket;
		status = AudioFileReadPackets(inAudioFile1,
									  false,
									  &bytesRead1,
									  NULL,
									  packetNum1,
									  &numPackets1,
									  buffer1);

		if (status) {
			goto reterr;
		}

		// if buffer was not filled, fill with zeros

		if (bytesRead1 < BUFFER_SIZE) {
			bzero(buffer1 + bytesRead1, (BUFFER_SIZE - bytesRead1));
		}

		packetNum1 += numPackets1;
    if (mixpacketNum > offset*BUFFER_SIZE) {
      numPackets2 = BUFFER_SIZE / inputDataFormat.mBytesPerPacket;
      status = AudioFileReadPackets(inAudioFile2,
                                    false,
                                    &bytesRead2,
                                    NULL,
                                    packetNum2,
                                    &numPackets2,
                                    buffer2);
      
      if (status) {
        goto reterr;
      }
    } else {
      bytesRead2 = 0;
    }
    
    // if buffer was not filled, fill with zeros
    
    if (bytesRead2 < BUFFER_SIZE) {
      bzero(buffer2 + bytesRead2, (BUFFER_SIZE - bytesRead2));
    }
    
    packetNum2 += numPackets2;
    
    // If no frames were returned, conversion is finished
    if (numPackets1 == 0 && numPackets2 == 0 && packetNum2 > 0)
      break;

		// Write pcm data to output file

		int maxNumPackets;
		if (numPackets1 > numPackets2) {
			maxNumPackets = numPackets1;
		} else if (numPackets1 == 0 && numPackets2 == 0) {
      maxNumPackets = 1;
    } else {
			maxNumPackets = numPackets2;
		}

		int numSamples = (maxNumPackets * inputDataFormat.mBytesPerPacket) / sizeof(int16_t);

		BOOL clipping = mix_buffers((const int16_t *)buffer1, (const int16_t *)buffer2,
									(int16_t *) mixbuffer, numSamples);

		if (clipping) {
			status = OSSTATUS_MIX_WOULD_CLIP;
			goto reterr;
		}

		// write the mixed packets to the output file

		UInt32 packetsWritten = maxNumPackets;

		status = AudioFileWritePackets(mixAudioFile,
										FALSE,
										(maxNumPackets * inputDataFormat.mBytesPerPacket),
										NULL,
										mixpacketNum,
										&packetsWritten,
										mixbuffer);

		if (status) {
			goto reterr;
		}

		if (packetsWritten != maxNumPackets) {
			status = kAudioFileInvalidPacketOffsetError;
			goto reterr;
		}

		mixpacketNum += packetsWritten;
	}

reterr:
	if (inAudioFile1 != NULL) {
		close_status = AudioFileClose(inAudioFile1);
		assert(close_status == 0);
	}
	if (inAudioFile2 != NULL) {
		close_status = AudioFileClose(inAudioFile2);
		assert(close_status == 0);
	}
	if (mixAudioFile != NULL) {
		close_status = AudioFileClose(mixAudioFile);
		assert(close_status == 0);
	}
	if (status == OSSTATUS_MIX_WOULD_CLIP) {
		char *mixfile_str = (char*) [mixURL.path UTF8String];
		close_status = unlink(mixfile_str);
		assert(close_status == 0);
	}
	if (buffer1 != NULL) {
		free(buffer1);
	}
	if (buffer2 != NULL) {
		free(buffer2);
	}
	if (mixbuffer != NULL) {
		free(mixbuffer);
	}

	return status;
}



static void CheckResult(OSStatus result, const char *operation)
{
	if (result == noErr) return;
	
	char errorString[20];
	// see if it appears to be a 4-char-code
	*(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(result);
	if (isprint(errorString[1]) && isprint(errorString[2]) && isprint(errorString[3]) && isprint(errorString[4])) {
		errorString[0] = errorString[5] = '\'';
		errorString[6] = '\0';
	} else
		// no, format it as an integer
		sprintf(errorString, "%d", (int)result);
	
	fprintf(stderr, "Error: %s (%s)\n", operation, errorString);
	
	exit(1);
}

#pragma mark - audio converter -
void Convert(MyAudioConverterSettings *mySettings)
{
	
	UInt32 outputBufferSize = 32 * 1024; // 32 KB is a good starting point
	UInt32 sizePerPacket = mySettings->outputFormat.mBytesPerPacket;
	UInt32 packetsPerBuffer = outputBufferSize / sizePerPacket;
	
	// allocate destination buffer
	UInt8 *outputBuffer = (UInt8 *)malloc(sizeof(UInt8) * outputBufferSize);
	
	UInt32 outputFilePacketPosition = 0; //in bytes
	while(1)
	{
		// wrap the destination buffer in an AudioBufferList
		AudioBufferList convertedData;
		convertedData.mNumberBuffers = 1;
		convertedData.mBuffers[0].mNumberChannels = mySettings->outputFormat.mChannelsPerFrame;
		convertedData.mBuffers[0].mDataByteSize = outputBufferSize;
		convertedData.mBuffers[0].mData = outputBuffer;
		
		UInt32 frameCount = packetsPerBuffer;
		
		// read from the extaudiofile
		CheckResult(ExtAudioFileRead(mySettings->inputFile,
                                     &frameCount,
                                     &convertedData),
                    "Couldn't read from input file");
		
		if (frameCount == 0) {
			printf ("done reading from file");
			return;
		}
		
		// write the converted data to the output file
		CheckResult (AudioFileWritePackets(mySettings->outputFile,
                                           FALSE,
                                           frameCount,
                                           NULL,
                                           outputFilePacketPosition / mySettings->outputFormat.mBytesPerPacket,
                                           &frameCount,
                                           convertedData.mBuffers[0].mData),
                     "Couldn't write packets to file");
		
		// advance the output file write location
		outputFilePacketPosition += (frameCount * mySettings->outputFormat.mBytesPerPacket);
	}
	
	// AudioConverterDispose(audioConverter);
}


@end
