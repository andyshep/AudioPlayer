//
//  ToolbarController.swift
//  AudioPlayer
//
//  Created by Andrew Shepard on 3/22/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Cocoa

final class ToolbarController: NSObject {
        
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet weak var stopButton: NSButton!
    @IBOutlet weak var playbackControls: NSSegmentedControl!
//    @IBOutlet weak var playbackControls: NSSegmentedControl!
    
    override class func awakeFromNib() {
        super.awakeFromNib()
        
        let bar = NSProgressIndicator()
        bar.style = .bar
        bar.controlSize = .mini
    }
}
