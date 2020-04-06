//
//  PlaylistViewController.swift
//  AudioPlayer
//
//  Created by Andrew Shepard on 3/17/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Cocoa
import Combine

final class PlaylistViewController: NSViewController {
    
    // MARK: IBOutlets
    
    @IBOutlet private weak var tableView: NSTableView!
    @IBOutlet private weak var statusLabel: NSTextField!
    
    // MARK: Private (properties)
    
    private let viewModel: PlaylistViewModel
    private var cancellables: [AnyCancellable] = []
    
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
        
        statusLabel.stringValue = ""
        
        tableView.doubleClickPublisher
            .receive(subscriber: viewModel.playEvent)
        
        viewModel.countPublisher
            .print()
            .sink { [weak self] (count) in
                self?.statusLabel.stringValue = "\(count) tracks"
            }
            .store(in: &cancellables)

        tableView.bind(.content, to: viewModel.arrayController, withKeyPath: "arrangedObjects")
        tableView.bind(.selectionIndexes, to: viewModel.arrayController, withKeyPath: "selectionIndexes")
        
        tableView.registerForDraggedTypes([.fileURL])
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
            guard let urls = representedObject as? [URL] else { return }
            viewModel.updatePlaylist(with: urls)
        }
    }
}

extension PlaylistViewController: NSTableViewDataSource {
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        return .copy
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        return true
    }
}
