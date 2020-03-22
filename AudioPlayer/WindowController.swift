//
//  WindowController.swift
//  AudioPlayer
//
//  Created by Andrew Shepard on 3/17/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Cocoa
import Combine

final class WindowController: NSWindowController {
    
    // MARK: IBOutlets
    
    @IBOutlet private weak var addButton: NSButton!
    @IBOutlet private weak var playButton: NSButton!
    @IBOutlet private weak var stopButton: NSButton!
    
    // MARK: Private (properties)
    
//    private lazy var openPanel: NSOpenPanel = {
//        let openPanel = NSOpenPanel()
//        openPanel.canChooseFiles = true
//        openPanel.allowsMultipleSelection = true
//        openPanel.canChooseDirectories = false
//        openPanel.canCreateDirectories = false
//        openPanel.allowedFileTypes = ["mp3", "wav", "aac", "flac"]
//
//        return openPanel
//    }()
    
    private var cancellables: [AnyCancellable] = []
    private let playbackController = PlaybackController()
    
    // MARK: - Lifecycle

    override func windowDidLoad() {
        super.windowDidLoad()
        
        guard let window = window else { return }
    
        window.titleVisibility = .hidden
        window.center()
        
        let (viewController, playlistViewModel) = Factory.makePlaylist(controller: playbackController)
        handle(viewModel: playlistViewModel)
        
        window.contentViewController = viewController
        
        addButton.publisher
            .flatMapLatest { _ in
                NSOpenPanel
                    .show(window, allowedFileTypes: ["mp3", "wav", "aac", "flac"])
                    .eraseToAnyPublisher()
            }
            .sink { urls in
                self.window?.contentViewController?.representedObject = urls
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private
    
    private func handle(viewModel: PlaylistViewModel) {
        playButton.publisher
            .receive(subscriber: viewModel.playEvent)
        
        stopButton.publisher
            .receive(subscriber: viewModel.stopEvent)
    }
}
