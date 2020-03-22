//
//  AudioTypes.swift
//  AudioPlayer
//
//  Created by Andrew Shepard on 3/14/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import AudioToolbox

/// Error that occurs when handling audio
public enum AudioError: Error {
    case cannotOpenFile
}

/// Structure to manage audio format and audio queue state information.
public class AudioPlayerState {
    var audioFile: AudioFileID?
    var isRunning = false
    
    var currentPacket: Int64 = 0
    var numberPacketsToRead: UInt32 = 0
    var packetDescriptions: UnsafeMutablePointer<AudioStreamPacketDescription>?
    
    func open(url: URL) throws {
        let result = AudioFileOpenURL(url as CFURL, .readPermission, 0, &audioFile)
        guard result < 0 else { throw AudioError.cannotOpenFile }
        
        // AudioFileOpenWithCallbacks
    }
    
    deinit {
        packetDescriptions?.deallocate()
    }
}

/// Buffer size
public typealias BufferSize = (size: UInt32, numberOfPackets: UInt32)
