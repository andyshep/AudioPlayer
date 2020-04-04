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
        
        setMetadataProperties(for: url)
        calculatePlaybackDuration(for: url)
    }
    
    private func setMetadataProperties(for url: URL) {
        let asset = AVAsset(url: path)
        asset.availableMetadataFormats.forEach { format in
            asset.metadata(forFormat: format).forEach { metadata in
                guard let commonKey = metadata.commonKey else { return }
                
                switch commonKey {
                case .commonKeyArtist:
                    self.artist = metadata.stringValue ?? ""
                case .commonKeyTitle:
                    self.title = metadata.stringValue ?? ""
                case .commonKeyAlbumName:
                    self.album = metadata.stringValue ?? ""
                default:
                    break
                }
            }
        }
    }
    
    private func calculatePlaybackDuration(for url: URL) {
        
        // https://stackoverflow.com/a/43890305
        
        var audioFileID: AudioFileID?
        AudioFileOpenURL(url as CFURL, .readPermission, 0, &audioFileID)
        
        var outDataSize: Float64 = 0
        var propSize = UInt32(MemoryLayout.size(ofValue: outDataSize))
        
        if let audioFileID = audioFileID {
            AudioFileGetProperty(
                audioFileID,
                kAudioFilePropertyEstimatedDuration,
                &propSize,
                &outDataSize
            )
            AudioFileClose(audioFileID)
        }
        
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
