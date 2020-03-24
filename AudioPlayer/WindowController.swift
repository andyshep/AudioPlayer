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
    @IBOutlet private weak var stopButton: NSButton!
    @IBOutlet private weak var playbackControls: NSSegmentedControl!
    
    @IBOutlet private weak var progressLabel: NSTextField!
    @IBOutlet private weak var progressBar: NSProgressIndicator!
    
    @IBOutlet private weak var toolbarController: ToolbarController!
    
    // MARK: Private (properties)
    
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
        
//        let (toolbar, toolbarViewModel) = Factory.makeToolbar(controller: playbackController)
        
        window.contentViewController = viewController
//        window.toolbar = toolbar
        
//        addButton.publisher
//            .flatMapLatest { _ in
//                NSOpenPanel
//                    .show(window, allowedFileTypes: ["mp3", "wav", "aac", "flac"])
//                    .eraseToAnyPublisher()
//            }
//            .sink { urls in
//                self.window?.contentViewController?.representedObject = urls
//            }
//            .store(in: &cancellables)
    }
    
    // MARK: - Private
    
    private func handle(viewModel: PlaylistViewModel) {
//        stopButton.publisher
//            .receive(subscriber: viewModel.stopEvent)
//        
//        playbackControls
//            .playEvent
//            .receive(subscriber: viewModel.playEvent)
//        
//        progressLabel.stringValue = "Testing"
    }
}

private extension NSSegmentedControl {
    var playEvent: AnyPublisher<Void, Never> {
        return publisher
            .filter { $0 == 1 }
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}
