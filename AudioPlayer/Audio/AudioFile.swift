//
//  AudioFile.swift
//  AudioPlayer
//
//  Created by Andrew Shepard on 3/18/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Foundation
import AVFoundation

final class AudioFile: NSObject {
    @objc var filename: String {
        return path.lastPathComponent
    }
    
    let path: URL
    
    @objc private(set) var title: String = ""
    @objc private(set) var artist: String = ""
    @objc private(set) var album: String = ""
    @objc private(set) var duration: String = ""
    
    init(path url: URL) {
        self.path = url
        
        super.init()
        
        readAudioInformation()
    }
    
    private func readAudioInformation() {
        var audioFileID: AudioFileID?
        
        CheckError(
            AudioFileOpenURL(path as CFURL, .readPermission, 0, &audioFileID),
            "Could not open audio file"
        )
        
        if let audioFileID = audioFileID {
            setMetadataProperties(from: audioFileID)
            calculatePlaybackDuration(from: audioFileID)
            
            AudioFileClose(audioFileID)
        }
    }
    
    private func setMetadataProperties(from audioFileID: AudioFileID) {
        var infoDictionary = NSDictionary()
        var propSize = UInt32(MemoryLayout.size(ofValue: infoDictionary))
        
        AudioFileGetProperty(
            audioFileID,
            kAudioFilePropertyInfoDictionary,
            &propSize,
            &infoDictionary
        )
        
        self.album = infoDictionary["album"] as? String ?? ""
        self.artist = infoDictionary["artist"] as? String ?? ""
        self.title = infoDictionary["title"] as? String ?? ""
    }
    
    private func calculatePlaybackDuration(from audioFileID: AudioFileID) {
        var outDataSize: Float64 = 0
        var propSize = UInt32(MemoryLayout.size(ofValue: outDataSize))
        
        AudioFileGetProperty(
            audioFileID,
            kAudioFilePropertyEstimatedDuration,
            &propSize,
            &outDataSize
        )
        AudioFileClose(audioFileID)
        
        let interval = TimeInterval(Int(outDataSize))
        let formatter = DateComponentsFormatter.shortStyle
        guard let duration = formatter.string(from: interval) else { return }
        
        self.duration = duration
    }
}

private extension DateComponentsFormatter {
    static var shortStyle: DateComponentsFormatter {
        // https://stackoverflow.com/a/43890305
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        
        return formatter
    }
}
