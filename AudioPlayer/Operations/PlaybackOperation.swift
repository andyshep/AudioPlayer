//
//  PlaybackOperation.swift
//  AudioPlayer
//
//  Created by Andrew Shepard on 3/21/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Foundation

protocol PlaybackOperation: Operation {
    
    var position: Double { get }
    var duration: Double { get }
    
    func startPlayback()
    func stopPlayback()
}
