//
//  AudioEngine.m
//  AudioPlayer
//
//  Created by Andrew Shepard on 4/4/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

#import "AudioEngine.h"

#import "AudioHelpers.h"
#import "FLACAudioPlayback.h"
#import "MP3AudioPlayback.h"

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
    
    NSDictionary *infoDictionary;
    propSize = sizeof(infoDictionary);
    CheckError(
        AudioFileGetProperty(
            _playbackState.audioFileID,
            kAudioFilePropertyInfoDictionary,
            &propSize,
            &infoDictionary
        ),
        "couldn't get file's data format"
    );
    
    if (dataFormat.mFormatID == kAudioFormatFLAC) {
        os_log_info(OS_LOG_DEFAULT, "%s: found FLAC audio file", __FUNCTION__);
        
        [self startPlaybackOfFLAC:dataFormat dictionary:infoDictionary];
    } else if (dataFormat.mFormatID == kAudioFormatMPEGLayer3) {
        os_log_info(OS_LOG_DEFAULT, "%s: found MP3 audio file", __FUNCTION__);
        
        [self startPlaybackOfMP3:dataFormat dictionary:infoDictionary];
    } else {
        os_log_error(OS_LOG_DEFAULT, "%s: unsupported audio format", __FUNCTION__);
        return;
    }
    
    CheckError(
        AudioQueueStart(_audioQueueRef, NULL),
        "AudioQueueStart failed"
    );
}

- (void)startPlaybackOfFLAC:(AudioStreamBasicDescription)dataFormat dictionary:(NSDictionary *)info {
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
    FLACCalculateBufferSize(
        _playbackState.audioFileID,
        dataFormat,
        0.5, // one half second of audio
        &bufferByteSize,
        &_playbackState.packets_to_read
    );
    
    UInt32 packetCount = _playbackState.packets_to_read;
    size_t packetDescriptionsSize = sizeof(AudioStreamPacketDescription) * packetCount;
    _playbackState.packetDescriptions = (AudioStreamPacketDescription *) malloc(packetDescriptionsSize);
    
    AudioQueueBufferRef buffers[kNumberPlaybackBuffers];
    _playbackState.isDone = false;
    _playbackState.current_packet = 0;
    
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
}

- (void)startPlaybackOfMP3:(AudioStreamBasicDescription)dataFormat dictionary:(NSDictionary *)info {
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
    MP3CalculateBufferSize(
        _playbackState.audioFileID,
        dataFormat,
        0.5, // one half second of audio
        &bufferByteSize,
        &_playbackState.packets_to_read
    );
    
    // check if we are dealing with a VBR file. ASBDs for VBR files always have
    // mBytesPerPacket and mFramesPerPacket as 0 since they can fluctuate at any time.
    // If we are dealing with a VBR file, we allocate memory to hold the packet descriptions
    bool isFormatVBR = (dataFormat.mBytesPerPacket == 0 || dataFormat.mFramesPerPacket == 0);
    if (isFormatVBR) {
        UInt32 packetCount = _playbackState.packets_to_read;
        size_t packetDescriptionsSize = sizeof(AudioStreamPacketDescription) * packetCount;
        _playbackState.packetDescriptions = (AudioStreamPacketDescription *) malloc(packetDescriptionsSize);
    } else {
        _playbackState.packetDescriptions = NULL;
    }
    
    AudioQueueBufferRef buffers[kNumberPlaybackBuffers];
    _playbackState.isDone = false;
    _playbackState.current_packet = 0;
    
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
}

/// Number of audio buffers to during playback 
static const UInt32 kNumberPlaybackBuffers = 3;

@end
