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
    
    let queue = DispatchQueue.init(label: "trst")
    
    func play(url: URL) {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return }
        let preamble = handle.readData(ofLength: 64)
        guard let mime = Swime.mimeType(data: preamble) else { return }
        guard mime.isAudio else {
            os_log("Unrecognized audio file: %{PUBLIC}@", log: .default, type: .error, url.lastPathComponent)
            return
        }
        
        let operation = createOperation(url: url, mime: mime)
        operationQueue.addOperation(operation)
        
        activeOperation = operation
    }
    
    func stop() {
        operationQueue.cancelAllOperations()
    }
    
    private func createOperation(url: URL, mime: MimeType) -> PlaybackOperation {
        switch mime.type {
        case .mp3:
            return MP3Operation(url: url)
        case .flac:
            return FLACOperation(url: url)
        default:
            fatalError()
        }
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
