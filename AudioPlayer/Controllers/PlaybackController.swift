//
//  PlaybackController.swift
//  AudioPlayer
//
//  Created by Andrew Shepard on 3/19/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Foundation
import Combine
import os.log

final class PlaybackController {
    
    private let operationQueue = OperationQueue()
    private var activeOperation: PlaybackOperation?
    
    func play(url: URL) {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return }
        let preamble = handle.readData(ofLength: 64)
        guard let mime = Swime.mimeType(data: preamble) else { return }
        guard mime.isAudio else {
            os_log("Unrecognized audio file: %{PUBLIC}@", log: .default, type: .error, url.lastPathComponent)
            return
        }
        
        let operation = MP3Operation(url: url)
        operationQueue.addOperation(operation)
        
        activeOperation = operation
    }
    
    func stop() {
        operationQueue.cancelAllOperations()
    }
}

private extension MimeType {
    var isAudio: Bool {
        switch self.type {
        case .mp3, .flac, .wav:
            return true
        default:
            return false
        }
    }
}
