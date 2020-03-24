//
//  ToolbarViewModel.swift
//  AudioPlayer
//
//  Created by Andrew Shepard on 3/22/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Cocoa
import Combine

final class ToolbarViewModel: NSObject {
    private let controller: PlaybackController
    
    init(controller: PlaybackController) {
        self.controller = controller
        super.init()
    }
}
