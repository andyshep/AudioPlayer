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
    private let audioEngine = AudioEngine()
    
    let queue = DispatchQueue.init(label: "trst")
    
    func play(url: URL) {
        audioEngine.startPlayback(of: url)
    }
    
    func stop() {
        audioEngine.stopPlayback()
    }
}
