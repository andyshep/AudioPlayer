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

typedef void (*AudioProgressProc)(const double progress, void* __nullable userData);

/// Structure to manage audio format and queue state information during playback.
struct MyAudioPlaybackState {
    AudioFileID __nullable audioFileID;
    AudioStreamPacketDescription* __nullable packetDescriptions;
    
    SInt64 currentPacket;
    SInt64 totalPacketCount;
    
    UInt32 packetsToRead;
    
    bool isDone;
    
    AudioProgressProc __nullable progressCallback;
    void* __nullable userData;
};

/// Checks if the `OSStatus` contains an error
/// @param error The status code to check against
/// @param operation A message to if the operation has failed
void CheckError(OSStatus error, const char * __nonnull operation);

/// Copies the magic cookie onto the encoder queue
/// @param audioFileID AudioFile to retrieve the magic cookie from
/// @param queue AudioQueue to copy cookie onto
void CopyEncoderCookieToQueue(AudioFileID __nonnull audioFileID,
                              AudioQueueRef __nonnull queue);

/// Calculates the buffer size to play inSeconds of audio, and number of packets
/// contained in the buffer.
/// @param inAudioFile AudioFile to use
/// @param inDesc AudioStreamBasicDescription
/// @param inSeconds Number of seconds of audio to buffer
/// @param outBufferSize On return, the buffer size necessary
/// @param outNumPackets On return, the number of packets in the buffer
void CalculateBufferSize(AudioFileID _Nonnull inAudioFile,
                         AudioStreamBasicDescription inDesc,
                         Float64 inSeconds,
                         UInt32 * _Nonnull outBufferSize,
                         UInt32 * _Nonnull outNumPackets);

/// Read callback for audio data
/// @param userData Pointer to user data to use within the callback
/// @param audioQueue AudioStreamBasicDescription
/// @param buffer A buffer to fill with audio data
void MyAudioQueueReadProc(void * __nullable userData,
                          AudioQueueRef __nonnull audioQueue,
                          AudioQueueBufferRef __nonnull buffer);

#endif /* AudioHelpers_h */
