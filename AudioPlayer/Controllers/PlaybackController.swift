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

final class PlaybackController: NSObject {
    
    private let operationQueue = OperationQueue()
    private let audioEngine = AudioEngine()
    
    let queue = DispatchQueue.init(label: "trst")
    
    @objc var title: String = ""
    
    func play(file: AudioFile) {
        audioEngine.startPlayback(of: file.path)
        
        willChangeValue(for: \.title)
        title = file.title
        didChangeValue(for: \.title)
    }
    
    func stop() {
        audioEngine.stopPlayback()
    }
}
