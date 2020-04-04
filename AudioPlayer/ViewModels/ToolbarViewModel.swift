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
    var songTitle: String = ""
    
    private let controller: PlaybackController
    private var cancellables: [AnyCancellable] = []
    
    init(controller: PlaybackController) {
        self.controller = controller
        super.init()
        
        let options = NSKeyValueObservingOptions.init(arrayLiteral: .new)
        KeyValueObservingPublisher
            .init(
                object: self.controller,
                keyPath: \PlaybackController.title,
                options: options
            )
            .sink { title in
                print("\(title)")
            }
            .store(in: &cancellables)
    }
}
