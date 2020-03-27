//
//  MP3PlaybackOperation.swift
//  AudioPlayer
//
//  Created by Andrew Shepard on 3/13/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Cocoa
import AudioToolbox
import os.log

final class MP3Operation: AsyncOperation {
    
    private var _duration: Double = 0.0
    
    private enum Constants {
        
        /// Number of audio queue buffers used for playback.
        static let playbackBufferCount = 3
    }
    
    private var playerState = AudioPlayerState()
    private var audioQueueRef: AudioQueueRef?
    
    private let url: URL

    init(url: URL) {
        self.url = url
        super.init()
    }
    
    override func cancel() {
        super.cancel()
        
        stopPlayback()
    }
    
    override func main() {
        super.main()
        
        startPlayback()
    }
}

extension MP3Operation: PlaybackOperation {
    @objc var position: Double {
        return 0.0
    }
    
    @objc var duration: Double {
        return _duration
    }
    
    internal func startPlayback() {
        os_log("Starting playback of file: %{PUBLIC}@", log: .default, type: .info, url.lastPathComponent)
        
        CheckError(
            AudioFileOpenURL(
                url as CFURL,
                AudioFilePermissions.readPermission,
                0,
                &playerState.audioFile
            ),
            onFailure: "AudioFileOpenURL failed"
        )

        guard let audioFile = playerState.audioFile else { return }

        var dataFormat = AudioStreamBasicDescription()
        var propSize: UInt32 = UInt32(MemoryLayout.size(ofValue: dataFormat))
        CheckError(
            AudioFileGetProperty(
                audioFile,
                kAudioFilePropertyDataFormat,
                &propSize,
                &dataFormat
            ),
            onFailure: "couldn't get file's data format"
        )
        
        var totalPacketCount: UInt64 = 0
        propSize = UInt32(MemoryLayout.size(ofValue: totalPacketCount))
        CheckError(
            AudioFileGetProperty(
                audioFile,
                kAudioFilePropertyAudioDataPacketCount,
                &propSize,
                &totalPacketCount
            ),
            onFailure: "couldn't get total packet count"
        )
        
        willChangeValue(for: \.duration)
        _duration = Double(totalPacketCount)
        didChangeValue(for: \.duration)

        CheckError(
            AudioQueueNewOutput(
                &dataFormat,
                AudioQueueCallback(userData:audioQueue:inputBuffer:),
                &playerState, // user data
                nil, // run loop
                nil, // run loop mode
                0, // flags (always 0)
                &audioQueueRef // output: reference to AudioQueue object
            ),
            onFailure: "AudioQueueNewOutput failed"
        )

        // adjust buffer size to represent about a half second
        let (bufferByteSize, numberPacketsToRead) = CalculateBufferSize(
            audioFile: audioFile,
            audioStreamDescription: dataFormat,
            secondsOfAudio: 0.5
        )

        playerState.numberPacketsToRead = numberPacketsToRead

        let isFormatVBR = (dataFormat.mBytesPerPacket == 0 || dataFormat.mFramesPerPacket == 0)
        if (isFormatVBR) {
            let sizeOfASPD = MemoryLayout<AudioStreamPacketDescription>.size
            let capacity = sizeOfASPD * Int(playerState.numberPacketsToRead)
            playerState.packetDescriptions = UnsafeMutablePointer<AudioStreamPacketDescription>
                .allocate(capacity: capacity)
        } else {
            playerState.packetDescriptions = nil
        }

        guard let audioQueue = audioQueueRef else { return }
        
        CopyEncoderCookieToQueue(audioFile: audioFile, audioQueue: audioQueue)

        var buffers = [AudioQueueBufferRef?](repeating: nil, count: 3)
        playerState.isRunning = false
        playerState.currentPacket = 0

        withUnsafeMutablePointer(to: &playerState) { statePtr in
            for index in 0..<Constants.playbackBufferCount {
                CheckError(
                    AudioQueueAllocateBuffer(
                        audioQueue,
                        bufferByteSize,
                        &buffers[index]
                    ),
                    onFailure: "AudioQueueAllocateBuffer failed"
                )

                if let buffer = buffers[index] {
                    AudioQueueCallback(
                        userData: statePtr,
                        audioQueue: audioQueue,
                        inputBuffer: buffer
                    )
                }

                if (statePtr.pointee.isRunning) { break }
            }
        }

        CheckError(AudioQueueStart(audioQueue, nil), onFailure: "AudioQueueStart failed")
    }
    
    internal func stopPlayback() {
        guard let queue = audioQueueRef else { return }
        guard let audioFile = playerState.audioFile else { return }
        
        os_log("Stopping playback", log: .default, type: .info)
        
        playerState.isRunning = true
//        CheckError(AudioQueueStop(queue, true), onFailure: "AudioQueueStop failed")
        AudioQueueStop(queue, true)
        
        AudioQueueDispose(queue, true)
        AudioFileClose(audioFile)
    }
}
