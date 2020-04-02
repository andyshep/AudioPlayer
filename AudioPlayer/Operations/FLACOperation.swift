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

        
//        guard let decoder = FLAC__stream_decoder_new() else {
//            os_log("Can't create FLAC decoder", log: .default, type: .error)
//            return
//        }
//
//        guard let filePtr = fopen(url.path, "r") else {
//            os_log("Can't open file for reading: %{PUBLIC}@", log: .default, type: .error, url.path)
//            return
//        }
//
//        let userData = FLACOperation.State(
//            operation: self,
//            playerState: playerState,
//            decoder: decoder.pointee
//        )
//
//        let userDataPtr = Unmanaged.passRetained(userData).toOpaque()
//
//        let result = FLAC__stream_decoder_init_stream(
//            decoder,
//            flacCallback.read,
//            nil,
//            nil,
//            flacCallback.length,
//            flacCallback.eof,
//            flacCallback.write,
//            flacCallback.metadata,
//            flacCallback.error,
//            userDataPtr
//        )
//
//        guard result == FLAC__STREAM_DECODER_INIT_STATUS_OK else {
//            os_log("Can't create FLAC stream", log: .default, type: .error)
//            return
//        }
//
        print("woot?")
//
//        CheckError(
//            AudioFileOpenWithCallbacks(
//                userDataPtr,
//                readCallback(inClientDataPtr:inPosition:requestCount:bufferPtr:actualCountPtr:),
//                nil,
//                getSizeProc(inClientData:),
//                nil,
//                0,
//                &playerState.audioFile
//            ),
//            onFailure: "Failed to create AudioFileID"
//        )
//
////        // open the audio file
////        CheckError(AudioFileOpenURL(url as CFURL,
////                         AudioFilePermissions.readPermission,
////                         0,
////                         &playerState.audioFile), onFailure: "AudioFileOpenURL failed")
////
//        guard let audioFile = playerState.audioFile else {
//            os_log("Failed to create AudioFileID", log: .default, type: .error)
//            return
//        }
//
//        FLAC__stream_decoder_process_until_end_of_metadata(decoder)
////
//        // get the audio data format from the file
//        var dataFormat = AudioStreamBasicDescription()
//        var propSize: UInt32 = UInt32(MemoryLayout.size(ofValue: dataFormat))
//        CheckError(AudioFileGetProperty(audioFile,
//                             kAudioFilePropertyDataFormat,
//                             &propSize,
//                             &dataFormat), onFailure: "couldn't get file's data format")
//
//        print("testing: \(decoder)")
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

private func readCallback(inClientDataPtr: UnsafeMutableRawPointer,
                          inPosition: Int64,
                          requestCount: UInt32,
                          bufferPtr: UnsafeMutableRawPointer,
                          actualCountPtr: UnsafeMutablePointer<UInt32>) -> OSStatus {
    let userData = Unmanaged<FLACOperation.State>.fromOpaque(inClientDataPtr)
        .takeUnretainedValue()
    
    let decoder = userData.decoder
    
    print(userData.operation)
    
        return 0
//    }
}

private func writeProc(inClientDataPtr: UnsafeMutableRawPointer,
                       inPosition: Int64,
                       requestCount: UInt32,
                       bufferPtr: UnsafeRawPointer,
                       actualCountPtr: UnsafeMutablePointer<UInt32>) -> OSStatus {
    return 0
}

private func getSizeProc(inClientData: UnsafeMutableRawPointer) -> Int64 {
    return 0
}

private func setSizeProc(inClientData: UnsafeMutableRawPointer, size: Int64) -> OSStatus {
    return 0
}
