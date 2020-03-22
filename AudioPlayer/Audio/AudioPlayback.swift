//
//  AudioPlayer.swift
//  AudioPlayer
//
//  Created by Andrew Shepard on 3/10/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import AudioToolbox
import os.log

// https://github.com/derekli66/Learning-Core-Audio-Swift-SampleCode/tree/master/CH05_Player-Swift
// https://developer.apple.com/library/archive/documentation/MusicAudio/Conceptual/AudioQueueProgrammingGuide/AQPlayback/PlayingAudio.html

/// Callback function used to fill an audio buffer with content during playback
/// - Parameters:
///   - userData: Structure that contains state information for the audio queue
///   - audioQueue: The audio queue needing a buffer filled
///   - inputBuffer: An audio queue buffer to fill with data
public func AudioQueueCallback(userData: UnsafeMutableRawPointer?,
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

/// Calculate buffer size for audio data
/// - Parameters:
///   - audioFile: The audio file being played
///   - audioStreamDescription: The stream basic description associated with the audio queue
///   - secondsOfAudio: The size of the audio queue, in terms of second of audio
///   - bufferSize: Size of the audio queue buffer, in bytes
///   - numberOfPackets: Number of audio packets to read, per audio play callback
public func CalculateBufferSize(audioFile: AudioFileID,
                                audioStreamDescription: AudioStreamBasicDescription,
                                secondsOfAudio: Float64) -> BufferSize {
    
    // first check to see what the max size of a packet is, if it is bigger than our default
    // allocation size, that needs to become larger
    var maxPacketSize: UInt32 = 0
    var propSize = UInt32(MemoryLayout.size(ofValue: maxPacketSize))
    CheckError(
        AudioFileGetProperty(
            audioFile,
            kAudioFilePropertyPacketSizeUpperBound,
            &propSize,
            &maxPacketSize
        ),
        onFailure: "Couldn't get file's max packet size"
    )
    
    let maxBufferSize: UInt32 = 0x10000 // limit size to 64k
    let minBufferSize: UInt32 = 0x4000 // limit size to 16k
    
    var bufferSize: UInt32
    if (audioStreamDescription.mFramesPerPacket > 0) {
        let numPacketsForTime = audioStreamDescription.mSampleRate /
            Float64(audioStreamDescription.mFramesPerPacket) * secondsOfAudio
        bufferSize = UInt32(numPacketsForTime) * maxPacketSize
    } else {
        // if frames per packet is zero, return a default buffer size
        bufferSize = maxBufferSize > maxPacketSize ? maxBufferSize : maxPacketSize
    }
    
    // we are going to limit our size to our default
    if (bufferSize > maxBufferSize && bufferSize > maxPacketSize) {
        bufferSize = maxBufferSize
    } else {
        // also make sure we're not too small - we don't want to go the disk for too small chunks
        if (bufferSize < minBufferSize) {
            bufferSize = minBufferSize
        }
    }
    
    let numberOfPackets = bufferSize / maxPacketSize
    
    return (size: bufferSize, numberOfPackets: numberOfPackets)
}

public func CopyEncoderCookieToQueue(audioFile: AudioFileID, audioQueue: AudioQueueRef) {
    var propertySize: UInt32 = 0
    let result = AudioFileGetPropertyInfo(
        audioFile,
        kAudioFilePropertyMagicCookieData,
        &propertySize,
        nil
    )
    
    if (result == noErr && propertySize > 0) {
        let alignment = MemoryLayout<UInt8>.alignment
        var magicCookie: UnsafeMutableRawPointer = UnsafeMutableRawPointer.allocate(
            byteCount: Int(propertySize),
            alignment: alignment
        )
        CheckError(
            AudioFileGetProperty(
                audioFile,
                kAudioFilePropertyMagicCookieData,
                &propertySize,
                &magicCookie
            ),
            onFailure: "Get cookie from file failed"
        )
        
        CheckError(
            AudioQueueSetProperty(
                audioQueue,
                kAudioQueueProperty_MagicCookie,
                magicCookie,
                propertySize
            ),
            onFailure: "Set cookie on queue failed"
        )
        magicCookie.deallocate()
    }
}

public func CheckError(_ error: OSStatus, onFailure operation: String) {
    guard (error != noErr) else { return }
    if (error < 0) {
        os_log("OSStatus error found: %d", log: .default, type: .error, error)
    }
    
    let count = 5
    let stride = MemoryLayout<OSStatus>.stride
    let byteCount = stride * count
    
    var error_ = CFSwapInt32HostToBig(UInt32(error))
    var charArray = [CChar](repeating: 0, count: byteCount )
    withUnsafeBytes(of: &error_) { (buffer: UnsafeRawBufferPointer) in
        for (index, byte) in buffer.enumerated() {
            charArray[index + 1] = CChar(byte)
        }
    }
    
    let v1 = charArray[1], v2 = charArray[2], v3 = charArray[3], v4 = charArray[4]
    
    if (isprint(Int32(v1)) > 0 && isprint(Int32(v2)) > 0 &&
        isprint(Int32(v3)) > 0 && isprint(Int32(v4)) > 0) {
        
        charArray[0] = "\'".utf8CString[0]
        charArray[5] = "\'".utf8CString[0]
        guard let errStr = NSString(
            bytes: &charArray,
            length: charArray.count,
            encoding: String.Encoding.ascii.rawValue
        )
        else {
            os_log("Error: %{PUBLIC}@", log: .default, type: .error, error)
            return
        }
        
        os_log("Error: %{PUBLIC}@ %{PUBLIC}@", log: .default, type: .error, operation, errStr)
    } else {
        os_log("Error: %{PUBLIC}@", log: .default, type: .error, error)
    }
}
