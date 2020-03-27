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
        
        let (viewController, viewModel) = Factory.makePlaylist(controller: playbackController)
        
        bindToToolbarEvents(viewModel: viewModel, window: window)
        window.contentViewController = viewController
    }
    
    // MARK: - Private
    
    private func bindToToolbarEvents(viewModel: PlaylistViewModel, window: NSWindow) {
        toolbarController.addButton
            .publisher
            .flatMapLatest { _ in
                NSOpenPanel
                    .show(window, allowedFileTypes: ["mp3", "wav", "aac", "flac"])
                    .eraseToAnyPublisher()
            }
            .sink { urls in
                self.window?.contentViewController?.representedObject = urls
            }
            .store(in: &cancellables)
        
        toolbarController.stopButton
            .publisher
            .receive(subscriber: viewModel.stopEvent)
        
        toolbarController
            .playbackControls
            .playEvent
            .receive(subscriber: viewModel.playEvent)
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
