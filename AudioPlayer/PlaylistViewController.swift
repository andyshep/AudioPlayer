//
//  PlaylistViewController.swift
//  AudioPlayer
//
//  Created by Andrew Shepard on 3/17/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Cocoa

class PlaylistViewController: NSViewController {
    
    @IBOutlet private weak var tableView: NSTableView!
    
    @objc private var audioFiles: [AudioFile] = []
    
    lazy var playlistArrayController: NSArrayController = {
        let controller = NSArrayController()
        controller.bind(.contentArray, to: self, withKeyPath: "audioFiles")
        
        return controller
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.bind(.content, to: playlistArrayController, withKeyPath: "arrangedObjects")
        tableView.bind(.selectionIndexes, to: playlistArrayController, withKeyPath: "selectionIndexes")
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
            guard let urls = representedObject as? [URL] else { return }
            
            willChangeValue(for: \.audioFiles)
            audioFiles = urls.map { AudioFile(path: $0) }
            didChangeValue(for: \.audioFiles)
        }
    }
}
