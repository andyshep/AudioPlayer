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
import DrFLAC

final class FLACOperation: AsyncOperation {
    
    private enum Constants {
        
        /// Number of audio queue buffers for playback.
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
    
    private func startPlayback() {
        os_log("Starting playback of file: %{PUBLIC}@", log: .default, type: .info, url.lastPathComponent)
        
        let drflacPtr = url.withUnsafeFileSystemRepresentation { urlPtr in
            return drflac_open_file(urlPtr, nil)
        }
        
        guard let pFlac = drflacPtr else {
            os_log("Can't open file: %{PUBLIC}@", log: .default, type: .error, url.lastPathComponent)
            return
        }
        
        print("testing")
        
//        // open the audio file
//        CheckError(AudioFileOpenURL(url as CFURL,
//                         AudioFilePermissions.readPermission,
//                         0,
//                         &playerState.audioFile), onFailure: "AudioFileOpenURL failed")
//
//        guard let audioFile = playerState.audioFile else { return }
//
//        // get the audio data format from the file
//        var dataFormat = AudioStreamBasicDescription()
//        var propSize: UInt32 = UInt32(MemoryLayout.size(ofValue: dataFormat))
//        CheckError(AudioFileGetProperty(audioFile,
//                             kAudioFilePropertyDataFormat,
//                             &propSize,
//                             &dataFormat), onFailure: "couldn't get file's data format")
//
//        // create a output (playback) queue
//        CheckError(AudioQueueNewOutput(&dataFormat,
//                            AudioQueueCallback(userData:audioQueue:inputBuffer:),
//                            &playerState, // user data
//                            nil, // run loop
//                            nil, // run loop mode
//                            0, // flags (always 0)
//                            &audioQueueRef), // output: reference to AudioQueue object
//            onFailure: "AudioQueueNewOutput failed")
//
//        // adjust buffer size to represent about a half second
//        let (bufferByteSize, numberPacketsToRead) = CalculateBufferSize(
//            audioFile: audioFile,
//            audioStreamDescription: dataFormat,
//            secondsOfAudio: 0.5
//        )
//
//        playerState.numberPacketsToRead = numberPacketsToRead
//
//        // check if we are dealing with a VBR file. ASBD for VBR files always have
//        // mBytesPerPacket and mFramesPerPacket as 0 since they can fluctuate at any time
//        // if we are dealing with VBR file, we allocate memory t ohold the packet descriptions
//        let isFormatVBR = (dataFormat.mBytesPerPacket == 0 || dataFormat.mFramesPerPacket == 0)
//        if (isFormatVBR) {
//            let sizeOfASPD = MemoryLayout<AudioStreamPacketDescription>.size
//            playerState.packetDescriptions = UnsafeMutablePointer<AudioStreamPacketDescription>.allocate(capacity: sizeOfASPD * Int(playerState.numberPacketsToRead))
//        } else {
//            playerState.packetDescriptions = nil
//        }
//
//        guard let audioQueue = audioQueueRef else { return }
//        // get magic cookie from file and set on queue
//        CopyEncoderCookieToQueue(audioFile: audioFile, audioQueue: audioQueue)
//
//        // allocate the buffers and prime the queue with some data before starting
//        var buffers = [AudioQueueBufferRef?](repeating: nil, count: 3)
//        playerState.isRunning = false
//        playerState.currentPacket = 0
//
//        withUnsafeMutablePointer(to: &playerState) { statePtr in
//            for index in 0..<Constants.playbackBufferCount {
//                CheckError(AudioQueueAllocateBuffer(audioQueue,
//                                                    bufferByteSize,
//                                                    &buffers[index]), onFailure: "AudioQueueAllocateBuffer failed")
//
//                if let buffer = buffers[index] {
//                    // Manually invoke callback to fill buffers with data
//                    AudioQueueCallback(userData: statePtr, audioQueue: audioQueue, inputBuffer: buffer)
//                }
//
//                // EOF (the entire file's contents fit in the buffers)
//                if (statePtr.pointee.isRunning) { break }
//            }
//        }
//
//        // start the queue. This function retruns immediately and begins
//        CheckError(AudioQueueStart(audioQueue, nil), onFailure: "AudioQueueStart failed")
    }
    
    private func stopPlayback() {
        guard let queue = audioQueueRef else { return }
        guard let audioFile = playerState.audioFile else { return }
        
        os_log("Stopping playback", log: .default, type: .info)
        
        // end playback
        playerState.isRunning = true
        CheckError(AudioQueueStop(queue, true), onFailure: "AudioQueueStop failed")
        
        AudioQueueDispose(queue, true)
        AudioFileClose(audioFile)
    }
    
    private func readCallback(inClientDataPtr: UnsafeMutableRawPointer,
                              inPosition: Int64,
                              requestCount: UInt32,
                              bufferPtr: UnsafeMutableRawPointer,
                              actualCountPtr: UnsafeMutablePointer<UInt32>) -> OSStatus {
        return 0
    }
}
