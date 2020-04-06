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

@property (atomic, assign, readwrite, getter=isPlaying) BOOL playing;
@property (atomic, strong, readwrite) NSNumber *progress;

- (void)openAndPlayFileAtURL:(NSURL *)url;
- (void)updateProgress:(double)progress;

@end

@implementation AudioEngine

- (instancetype)init {
    if (self = [super init]) {
        self.audioQueue = dispatch_queue_create("playback", NULL);
        self.progress = [NSNumber numberWithDouble:0.0];
    }
    
    return self;
}

- (void)startPlaybackOfURL:(NSURL *)url {
    os_log_info(OS_LOG_DEFAULT, "%s: %s", __FUNCTION__, url.fileSystemRepresentation);
    
    if (self.isPlaying) {
        [self stopPlayback];
    }
    
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
            "Failed to stop audio queue"
        );
        
        AudioQueueDispose(self->_audioQueueRef, true);
        AudioFileClose(self->_playbackState.audioFileID);
    });
}

// MARK: - Private

- (void)updateProgress:(double)progress {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self willChangeValueForKey:@"progress"];
        self.progress = [NSNumber numberWithDouble:progress];
        [self didChangeValueForKey:@"progress"];
    });
}

- (void)openAndPlayFileAtURL:(NSURL *)url {
    CheckError(
        AudioFileOpenURL(
            (__bridge CFURLRef)url,
            kAudioFileReadPermission,
            0,  // file hint
            &_playbackState.audioFileID
        ),
        "Could not open audio file"
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
        "Could not determine audio file data format"
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
        "Could not find audio file info dictionary"
    );
    
    propSize = sizeof(_playbackState.totalPacketCount);
    CheckError(
        AudioFileGetProperty(
            _playbackState.audioFileID,
            kAudioFilePropertyAudioDataPacketCount,
            &propSize,
            &_playbackState.totalPacketCount
        ),
        "Could not find total packet count"
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
        "Could not create audio queue"
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
    
    _playbackState.progressCallback = MyProgressCallback;
    _playbackState.userData = (__bridge void *)self;
    
    for (UInt32 i = 0; i < kNumberPlaybackBuffers; ++i) {
        CheckError(
            AudioQueueAllocateBuffer(
                _audioQueueRef,
                bufferByteSize,
                &buffers[i]
            ),
            "Failed to allocate audio buffer"
        );
        
        MyAudioQueueReadProc(&_playbackState, _audioQueueRef, buffers[i]);
        
        if (_playbackState.isDone) break;
    }
    
    CheckError(
        AudioQueueStart(_audioQueueRef, NULL),
        "Failed to start audio queue"
    );
    
    self.playing = YES;
    
    [self willChangeValueForKey:@"songTitle"];
    _songTitle = [infoDictionary objectForKey:@"title"];
    [self didChangeValueForKey:@"songTitle"];
}

/// Number of audio buffers to during playback 
static const UInt32 kNumberPlaybackBuffers = 3;

@end

static void MyProgressCallback(const double progress, void* __nullable userData) {
//    os_log_info(OS_LOG_DEFAULT, "%s: %f", __FUNCTION__, progress);
    
    AudioEngine *audioEngine = (__bridge AudioEngine *)userData;
    if (audioEngine == nil) return;
    
    [audioEngine updateProgress:progress];
}
