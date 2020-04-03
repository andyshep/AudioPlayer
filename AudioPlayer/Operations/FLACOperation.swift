//
//  FLACOperation.swift
//  AudioPlayer
//
//  Created by Andrew Shepard on 3/13/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Cocoa
import AudioToolbox
import os.log
import CLibFLAC

final class FLACOperation: AsyncOperation, PlaybackOperation {
    
    final class State {
        let operation: FLACOperation
        let playerState: AudioPlayerState
        let decoder: FLAC__StreamDecoder
        
        init(operation: FLACOperation, playerState: AudioPlayerState, decoder: FLAC__StreamDecoder) {
            self.operation = operation
            self.playerState = playerState
            self.decoder = decoder
        }
    }
    
    var position: Double = 0.0
    var duration: Double = 0.0
    
    private enum Constants {
        
        /// Number of audio queue buffers for playback.
        static let playbackBufferCount = 3
    }
    
    private var playerState = AudioPlayerState()
    private var audioQueueRef: AudioQueueRef?
    
    private let flacCallback = FLACAudioCallback()
    
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
    
    func startPlayback() {
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

        // create a output (playback) queue
        CheckError(
            AudioQueueNewOutput(
                &dataFormat,
                FLACAudioQueueCallback(userData:audioQueue:inputBuffer:),
                &playerState,
                nil,
                nil,
                0,
                &audioQueueRef
            ),
            onFailure: "AudioQueueNewOutput failed"
        )
        
        // adjust buffer size to represent about a half second
        let (bufferByteSize, numberPacketsToRead) = FLACCalculateBufferSize(
            audioFile: audioFile,
            audioStreamDescription: dataFormat,
            secondsOfAudio: 0.5
        )

        playerState.numberPacketsToRead = numberPacketsToRead

        let sizeOfASPD = MemoryLayout<AudioStreamPacketDescription>.size
        let capacity = sizeOfASPD * Int(playerState.numberPacketsToRead)
        playerState.packetDescriptions = UnsafeMutablePointer<AudioStreamPacketDescription>
            .allocate(capacity: capacity)

        guard let audioQueue = audioQueueRef else { return }

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
                    FLACAudioQueueCallback(
                        userData: statePtr,
                        audioQueue: audioQueue,
                        inputBuffer: buffer
                    )
                }
                
//                if (playerState.isRunning) { break }
            }
        }

        CheckError(AudioQueueStart(audioQueue, nil), onFailure: "AudioQueueStart failed")
    }
    
    func stopPlayback() {
        guard let queue = audioQueueRef else { return }
        guard let audioFile = playerState.audioFile else { return }
        
        os_log("Stopping playback", log: .default, type: .info)
        
        // end playback
        playerState.isRunning = true
        CheckError(AudioQueueStop(queue, true), onFailure: "AudioQueueStop failed")
        
        AudioQueueDispose(queue, true)
        AudioFileClose(audioFile)
    }
}

/// Callback function used to fill an audio buffer with content during playback
/// - Parameters:
///   - userData: Structure that contains state information for the audio queue
///   - audioQueue: The audio queue needing a buffer filled
///   - inputBuffer: An audio queue buffer to fill with data
private func FLACAudioQueueCallback(userData: UnsafeMutableRawPointer?,
                                    audioQueue: AudioQueueRef,
                                    inputBuffer: AudioQueueBufferRef) {
    let userDataPtr = userData?.bindMemory(to: AudioPlayerState.self, capacity: 1)
    
    guard
        let audioPlaybackState = userDataPtr?.pointee,
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
            true,
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

public func FLACCalculateBufferSize(audioFile: AudioFileID,
                                    audioStreamDescription: AudioStreamBasicDescription,
                                    secondsOfAudio: Float64) -> BufferSize {
    var packetSizeUpperBound: UInt32 = 0
    var propSize = UInt32(MemoryLayout.size(ofValue: packetSizeUpperBound))
    CheckError(
        AudioFileGetProperty(
            audioFile,
            kAudioFilePropertyPacketSizeUpperBound,
            &propSize,
            &packetSizeUpperBound
        ),
        onFailure: "Couldn't get file's max packet size"
    )
    
    let numberOfPackets: UInt32 = 2
    let bufferSize: UInt32 = packetSizeUpperBound * numberOfPackets
    
    return (size: bufferSize, numberOfPackets: numberOfPackets)
}
