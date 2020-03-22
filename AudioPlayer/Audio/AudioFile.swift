//
//  AudioFile.swift
//  AudioPlayer
//
//  Created by Andrew Shepard on 3/18/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Foundation

final class AudioFile: NSObject {
    @objc var filename: String {
        return path.lastPathComponent
    }
    
    let path: URL
    
    init(path: URL) {
        self.path = path
    }
}
