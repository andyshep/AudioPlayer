//
//  PlaybackController.swift
//  AudioPlayer
//
//  Created by Andrew Shepard on 3/19/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Foundation
import Combine

final class PlaybackController {
    
    private let operationQueue = OperationQueue()
    private var activeOperation: PlaybackOperation?
    
    init() {
        
    }
    
    func play(url: URL) {
        let operation = MP3Operation(url: url)
        operationQueue.addOperation(operation)
        
        activeOperation = operation
    }
    
    func stop() {
        operationQueue.cancelAllOperations()
    }
}
