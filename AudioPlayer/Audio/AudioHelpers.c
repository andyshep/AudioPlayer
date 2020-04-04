//
//  AudioHelpers.c
//  AudioPlayer
//
//  Created by Andrew Shepard on 4/4/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

#include "AudioHelpers.h"

#include <os/log.h>

void CheckError(OSStatus error, const char * _Nonnull operation) {
    if (error == noErr) return;
    
    char str[20];
    *(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
    if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
        str[0] = str[5] = '\'';
        str[6] = '\0';
    } else {
        sprintf(str, "%d", (int)error);
    }
    
    fprintf(stderr, "Error: %s (%s)\n", operation, str);
}

void CopyEncoderCookieToQueue(AudioFileID __nonnull audioFileID,
                              AudioQueueRef __nonnull queue) {
    UInt32 propertySize;
    OSStatus result = AudioFileGetPropertyInfo(audioFileID,
                                               kAudioFilePropertyMagicCookieData,
                                               &propertySize,
                                               NULL);
    if (result == noErr && propertySize > 0) {
        Byte *magicCookie = (UInt8*)malloc(sizeof(UInt8) * propertySize);
        CheckError(
            AudioFileGetProperty(
                audioFileID,
                kAudioFilePropertyMagicCookieData,
                &propertySize,
                magicCookie
            ),
            "Get cookie from file failed"
        );
        
        CheckError(
            AudioQueueSetProperty(
                queue,
                kAudioQueueProperty_MagicCookie,
                magicCookie,
                propertySize
            ),
            "Set cookie on audio queue failed"
        );
        free(magicCookie);
    }
}

void CalculateBufferSize(AudioFileID _Nonnull inAudioFile,
                         AudioStreamBasicDescription inDesc,
                         Float64 inSeconds,
                         UInt32 * _Nonnull outBufferSize,
                         UInt32 * _Nonnull outNumPackets) {
    UInt32 packetSizeUpperBound;
    UInt32 propSize = sizeof(packetSizeUpperBound);
    CheckError(
        AudioFileGetProperty(
            inAudioFile,
            kAudioFilePropertyPacketSizeUpperBound,
            &propSize,
            &packetSizeUpperBound
        ),
        "couldn't get file's max packet size"
    );
    
    if (inDesc.mFormatID == kAudioFormatFLAC) {
        os_log_info(OS_LOG_DEFAULT, "%s: found FLAC audio file", __FUNCTION__);
        
        UInt32 numberOfPackets = 2;
        UInt32 bufferSize = packetSizeUpperBound * numberOfPackets;
        
        *outBufferSize = bufferSize;
        *outNumPackets = numberOfPackets;
    } else if (inDesc.mFormatID == kAudioFormatMPEGLayer3) {
        os_log_info(OS_LOG_DEFAULT, "%s: found MP3 audio file", __FUNCTION__);
        
        static const int maxBufferSize = 0x10000;
        static const int minBufferSize = 0x4000;
        
        if (inDesc.mFramesPerPacket) {
            Float64 numPacketsForTime = inDesc.mSampleRate / inDesc.mFramesPerPacket * inSeconds;
            *outBufferSize = numPacketsForTime * packetSizeUpperBound;
        } else {
            *outBufferSize = maxBufferSize > packetSizeUpperBound ? maxBufferSize : packetSizeUpperBound;
        }
        
        if (*outBufferSize > maxBufferSize && *outBufferSize > packetSizeUpperBound) {
            *outBufferSize = maxBufferSize;
        } else {
            if (*outBufferSize < minBufferSize) {
                *outBufferSize = minBufferSize;
            }
        }
        
        *outNumPackets = *outBufferSize / packetSizeUpperBound;
    }
}

void MyAudioQueueReadProc(void* __nullable userData,
                          AudioQueueRef __nonnull audioQueue,
                          AudioQueueBufferRef __nonnull buffer) {
    struct MyAudioPlaybackState *playerState = (struct MyAudioPlaybackState *)userData;
    
    if (playerState->isDone) return;
    
    UInt32 numberBytes = buffer->mAudioDataBytesCapacity;
    UInt32 numberPackets = playerState->packetsToRead;
    
    CheckError(
        AudioFileReadPacketData(
            playerState->audioFileID,
            true,
            &numberBytes,
            playerState->packetDescriptions,
            playerState->currentPacket,
            &numberPackets,
            buffer->mAudioData
        ),
        "AudioFileReadPackets failed"
    );
    
    if (numberPackets > 0) {
        buffer->mAudioDataByteSize = numberBytes;
        CheckError(
            AudioQueueEnqueueBuffer(
                audioQueue,
                buffer,
                (playerState->packetDescriptions != NULL) ? numberPackets : 0,
                playerState->packetDescriptions
            ),
            "AudioQueueEnqueueBuffer failed"
        );
        
        playerState->currentPacket += numberPackets;
    } else {
        CheckError(
            AudioQueueStop(audioQueue, false),
            "AudioQueueStop failed"
        );
        
        playerState->isDone = true;
    }
}
