//
//  WindowController.swift
//  AudioPlayer
//
//  Created by Andrew Shepard on 3/17/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Cocoa
import Combine

class WindowController: NSWindowController {
    
    @IBOutlet private weak var addButton: NSButton!
    
    private lazy var openPanel: NSOpenPanel = {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.allowedFileTypes = ["mp3", "wav", "aac", "flac"]
        
        return openPanel
    }()
    
    lazy private var playlistViewController: PlaylistViewController = {
        guard let viewController = contentViewController as? PlaylistViewController else { fatalError() }
        return viewController
    }()
    
    private var cancellables: [AnyCancellable] = []

    override func windowDidLoad() {
        super.windowDidLoad()
    
        window?.titleVisibility = .hidden
        
        addButton.publisher
            .flatMap { [unowned self] _ in
                return self.openPanel
                    .showAndCompletion()
                    .eraseToAnyPublisher()
            }
            .compactMap { [weak self] (response) -> [URL]? in
                guard case .OK = response else { return nil }
                guard let urls = self?.openPanel.urls else { return nil }
                return urls
            }
            .sink { urls in
                self.playlistViewController.representedObject = urls
            }
            .store(in: &cancellables)
    }
}
