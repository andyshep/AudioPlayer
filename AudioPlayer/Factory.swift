//
//  Factory.swift
//  AudioPlayer
//
//  Created by Andrew Shepard on 3/21/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import AppKit

struct Factory {
    
    private static var storyboard: NSStoryboard = {
        guard let storyboard = NSStoryboard.main else { fatalError() }
        return storyboard
    }()
    
    static func makePlaylist(controller: PlaybackController) -> (NSViewController, PlaylistViewModel) {
        let viewModel = PlaylistViewModel(controller: controller)
        let viewController = storyboard.instantiateViewController(identifier: "PlaylistViewController") { coder in
            return PlaylistViewController(coder: coder, viewModel: viewModel)
        }
        return (viewController, viewModel)
    }
}
