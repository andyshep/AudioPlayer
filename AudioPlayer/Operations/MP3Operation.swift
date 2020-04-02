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
    
    var playerState = AudioPlayerState()
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
        var propSize: UInt32

        var dataFormat = AudioStreamBasicDescription()
        propSize = UInt32(MemoryLayout.size(ofValue: dataFormat))
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
        
        var infoDictionary = NSDictionary()
        propSize = UInt32(MemoryLayout.size(ofValue: infoDictionary))
        
        CheckError(
            AudioFileGetProperty(
                audioFile,
                kAudioFilePropertyInfoDictionary,
                &propSize,
                &infoDictionary
            ),
            onFailure: "couldn't get file property info dictionary"
        )

        CheckError(
            AudioQueueNewOutput(
                &dataFormat,
                MP3AudioQueueCallback(userData:audioQueue:inputBuffer:),
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

        let operationPtr = Unmanaged.passUnretained(self).toOpaque()
        
//        withUnsafeMutablePointer(to: &playerState) { statePtr in
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
                    MP3AudioQueueCallback(
                        userData: operationPtr,
                        audioQueue: audioQueue,
                        inputBuffer: buffer
                    )
                }

                if (playerState.isRunning) { break }
            }
//        }

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

/// Callback function used to fill an audio buffer with content during playback
/// - Parameters:
///   - userData: Structure that contains state information for the audio queue
///   - audioQueue: The audio queue needing a buffer filled
///   - inputBuffer: An audio queue buffer to fill with data
private func MP3AudioQueueCallback(userData: UnsafeMutableRawPointer?,
                                   audioQueue: AudioQueueRef,
                                   inputBuffer: AudioQueueBufferRef) {
    guard
        let operationPtr = userData?.assumingMemoryBound(to: Unmanaged<MP3Operation>.self)
    else { return }
    
    let operation = operationPtr.pointee.takeUnretainedValue()
    let audioPlaybackState = operation.playerState

    guard
        let audioFile = audioPlaybackState.audioFile,
        audioPlaybackState.isRunning == false
    else { return }
    
    // read audio data from file into supplied buffer
    // Set for input buffer size. This is required to prevent -50 error code
    var numberBytes: UInt32 = inputBuffer.pointee.mAudioDataBytesCapacity
    var numberPackets: UInt32 = audioPlaybackState.numberPacketsToRead
    
    CheckError(
        AudioFileReadPacketData(
            audioFile,
            false,
            &numberBytes,
            audioPlaybackState.packetDescriptions,
            audioPlaybackState.currentPacket,
            &numberPackets,
            inputBuffer.pointee.mAudioData
        ),
        onFailure: "AudioFileReadPackets failed"
    )
    
    // enqueue buffer into the Audio Queue
    // if numberPackets == 0, it means we are EOF (all data has been read from file)
    if (numberPackets > 0) {
        inputBuffer.pointee.mAudioDataByteSize = numberBytes
        CheckError(
            AudioQueueEnqueueBuffer(
                audioQueue,
                inputBuffer,
                (audioPlaybackState.packetDescriptions != nil) ? numberPackets : 0,
                audioPlaybackState.packetDescriptions
            ),
            onFailure: "AudioQueueEnqueueBuffer failed"
        )

        audioPlaybackState.currentPacket += Int64(numberPackets)
        debugPrint("packetPosition: \(audioPlaybackState.currentPacket)")
    } else {
        CheckError(
            AudioQueueStop(audioQueue, false),
            onFailure: "AudioQueueStop failed"
        )
        audioPlaybackState.isRunning = true
    }
}
