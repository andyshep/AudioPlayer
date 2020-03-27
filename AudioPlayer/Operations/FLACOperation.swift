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
    var position: Double = 0.0
    
    var duration: Double = 0.0
    
    
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
    
    func startPlayback() {
        os_log("Starting playback of file: %{PUBLIC}@", log: .default, type: .info, url.lastPathComponent)
        
        guard let decoder = FLAC__stream_decoder_new() else {
            os_log("Can't create FLAC decoder", log: .default, type: .error)
            return
        }
        
//        let drflacPtr = url.withUnsafeFileSystemRepresentation { urlPtr in
//            return drflac_open_file(urlPtr, nil)
//        }
//
//        guard let pFlac = drflacPtr else {
//            os_log("Can't open file: %{PUBLIC}@", log: .default, type: .error, url.lastPathComponent)
//            return
//        }
        
//        AudioFileOpenWithCallbacks(
//            pFlac,
//            readCallback(inClientDataPtr:inPosition:requestCount:bufferPtr:actualCountPtr:),
//            nil,
//            getSizeProc(inClientData:),
//            nil,
//            0,
//            &playerState.audioFile
//        )
        
        print("testing: \(decoder)")
        
//        // open the audio file
//        CheckError(AudioFileOpenURL(url as CFURL,
//                         AudioFilePermissions.readPermission,
//                         0,
//                         &playerState.audioFile), onFailure: "AudioFileOpenURL failed")
//
        guard let audioFile = playerState.audioFile else { return }
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
//    autoreleasepool {
//        let pFlac = inClientDataPtr.assumingMemoryBound(to: drflac.self)
//
////        pFlac.pointee
//
//        var floatBuffer = UnsafeMutablePointer<Float>.allocate(capacity: Int(requestCount))
//        var outputBufferPtr = bufferPtr.assumingMemoryBound(to: Float.self)
//
////        drflac__seek_to_byte(&pFlac.pointee.bs, drflac_uint64(inPosition))
//        let framesRead = drflac_read_pcm_frames_f32(pFlac, drflac_uint64(requestCount), floatBuffer)
//
//        actualCountPtr.pointee = UInt32(framesRead)
//
//        memcpy(bufferPtr, floatBuffer, Int(framesRead))
//
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
