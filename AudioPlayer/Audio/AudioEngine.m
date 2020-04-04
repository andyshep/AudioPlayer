//
//  AudioEngine.m
//  AudioPlayer
//
//  Created by Andrew Shepard on 4/4/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

#import "AudioEngine.h"
#import "AudioHelpers.h"

#import <os/log.h>

@interface AudioEngine()

@property (nonatomic, strong) dispatch_queue_t audioQueue;
@property (nonatomic, assign) struct MyAudioPlaybackState playbackState;

@property (nonatomic, assign) AudioQueueRef audioQueueRef;

- (void)openAndPlayFileAtURL:(NSURL *)url;

@end

@implementation AudioEngine

- (instancetype)init {
    if (self = [super init]) {
        self.audioQueue = dispatch_queue_create("playback", NULL);
    }
    
    return self;
}

- (void)startPlaybackOfURL:(NSURL *)url {
    os_log_info(OS_LOG_DEFAULT, "%s: %s", __FUNCTION__, url.fileSystemRepresentation);
    
    dispatch_async([self audioQueue], ^{
        [self openAndPlayFileAtURL:url];
    });
}

- (void)stopPlayback {
    os_log_info(OS_LOG_DEFAULT, "%s", __FUNCTION__);
    
    dispatch_async([self audioQueue], ^{
        self->_playbackState.isDone = true;
        
        CheckError(
            AudioQueueStop(self->_audioQueueRef, true),
            "AudioQueueStop failed"
        );
        
        AudioQueueDispose(self->_audioQueueRef, true);
        AudioFileClose(self->_playbackState.audioFileID);
    });
}

// MARK: - Private

- (void)openAndPlayFileAtURL:(NSURL *)url {
    CheckError(
        AudioFileOpenURL(
            (__bridge CFURLRef)url,
            kAudioFileReadPermission,
            0,  // file hint
            &_playbackState.audioFileID
        ),
        "could not open audio file"
    );
    
    if (_playbackState.audioFileID == NULL) {
        return;
    }
    
    AudioStreamBasicDescription dataFormat;
    UInt32 propSize = sizeof(dataFormat);
    CheckError(
        AudioFileGetProperty(
            _playbackState.audioFileID,
            kAudioFilePropertyDataFormat,
            &propSize,
            &dataFormat
        ),
        "couldn't get file's data format"
    );
    
    CheckError(
        AudioQueueNewOutput(
            &dataFormat,
            MyAudioQueueReadProc,
            &_playbackState,
            NULL,   // run loop
            NULL,   // run loop mode
            0,      // flags, always zero
            &_audioQueueRef
        ),
        "couldn't create audio queue"
    );
    
    UInt32 bufferByteSize;
    CalculateBufferSize(
        _playbackState.audioFileID,
        dataFormat,
        0.5, // one half second of audio
        &bufferByteSize,
        &_playbackState.packetsToRead
    );
    
    UInt32 packetCount = _playbackState.packetsToRead;
    size_t packetDescriptionsSize = sizeof(AudioStreamPacketDescription) * packetCount;
    _playbackState.packetDescriptions = (AudioStreamPacketDescription *) malloc(packetDescriptionsSize);
    
    CopyEncoderCookieToQueue(_playbackState.audioFileID, _audioQueueRef);
    
    AudioQueueBufferRef buffers[kNumberPlaybackBuffers];
    _playbackState.isDone = false;
    _playbackState.currentPacket = 0;
    
    for (UInt32 i = 0; i < kNumberPlaybackBuffers; ++i) {
        CheckError(
            AudioQueueAllocateBuffer(
                _audioQueueRef,
                bufferByteSize,
                &buffers[i]
            ),
            "AudioQueueAllocateBuffer failed"
        );
        
        MyAudioQueueReadProc(&_playbackState, _audioQueueRef, buffers[i]);
        
        if (_playbackState.isDone) break;
    }
    
    CheckError(
        AudioQueueStart(_audioQueueRef, NULL),
        "AudioQueueStart failed"
    );
}

/// Number of audio buffers to during playback 
static const UInt32 kNumberPlaybackBuffers = 3;

@end
