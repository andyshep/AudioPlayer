//
//  PlaybackController.swift
//  AudioPlayer
//
//  Created by Andrew Shepard on 3/19/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Foundation
import Combine

final class PlaybackController: NSObject {
    
    var audioInfoPublisher: AnyPublisher<String?, Never> {
        return audioEngine.audioInfoPublisher
            .eraseToAnyPublisher()
    }
    
    var progressPublisher: AnyPublisher<NSNumber, Never> {
        return audioEngine.progressPublisher
            .eraseToAnyPublisher()
    }
    
    private let audioEngine = AudioEngine()
    
    @objc var title: String = ""
    
    func play(file: AudioFile) {
        audioEngine.startPlayback(of: file.path)
    }
    
    func stop() {
        audioEngine.stopPlayback()
    }
}

private extension AudioEngine {
    var audioInfoPublisher: AnyPublisher<String?, Never> {
        return KeyValueObservingPublisher(
            object: self,
            keyPath: \AudioEngine.songTitle,
            options: .new
        )
        .eraseToAnyPublisher()
    }
    
    var progressPublisher: AnyPublisher<NSNumber, Never> {
        return KeyValueObservingPublisher(
            object: self,
            keyPath: \AudioEngine.progress,
            options: NSKeyValueObservingOptions.init(arrayLiteral: [.initial, .new])
        )
        .eraseToAnyPublisher()
    }
}
