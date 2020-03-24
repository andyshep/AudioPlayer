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
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
}
