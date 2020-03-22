//
//  PlaylistViewController.swift
//  AudioPlayer
//
//  Created by Andrew Shepard on 3/17/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Cocoa

final class PlaylistViewController: NSViewController {
    
    // MARK: IBOutlets
    
    @IBOutlet private weak var tableView: NSTableView!
    
    // MARK: Private (properties)
    
    private let viewModel: PlaylistViewModel
    
    // MARK: Lifecycle
    
    init?(coder: NSCoder, viewModel: PlaylistViewModel) {
        self.viewModel = viewModel
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.bind(.content, to: viewModel.arrayController, withKeyPath: "arrangedObjects")
        tableView.bind(.selectionIndexes, to: viewModel.arrayController, withKeyPath: "selectionIndexes")
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
            guard let urls = representedObject as? [URL] else { return }
            viewModel.updatePlaylist(with: urls)
        }
    }
}
