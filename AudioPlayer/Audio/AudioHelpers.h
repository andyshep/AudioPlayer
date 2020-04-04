//
//  AudioHelpers.h
//  AudioPlayer
//
//  Created by Andrew Shepard on 4/4/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

#ifndef AudioHelpers_h
#define AudioHelpers_h

#include <AudioToolbox/AudioToolbox.h>

/// Structure to manage audio format and queue state information during playback.
struct MyAudioPlaybackState {
    AudioFileID _Nullable audioFileID;
    AudioStreamPacketDescription* _Nullable packetDescriptions;
    
    SInt64 currentPacket;
    UInt32 packetsToRead;
    
    bool isDone;
};

/// Checks if the `OSStatus` contains an error
/// @param error The status code to check against
/// @param operation A message to if the operation has failed
void CheckError(OSStatus error, const char * _Nonnull operation);

void CopyEncoderCookieToQueue(AudioFileID __nonnull audioFileID,
                              AudioQueueRef __nonnull queue);

void CalculateBufferSize(AudioFileID _Nonnull inAudioFile,
                         AudioStreamBasicDescription inDesc,
                         Float64 inSeconds,
                         UInt32 * _Nonnull outBufferSize,
                         UInt32 * _Nonnull outNumPackets);

void MyAudioQueueReadProc(void * __nullable userData,
                          AudioQueueRef __nonnull audioQueue,
                          AudioQueueBufferRef __nonnull buffer);

#endif /* AudioHelpers_h */
