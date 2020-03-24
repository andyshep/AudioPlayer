//
//  NSOpenPanel+Combine.swift
//  AudioPlayer
//
//  Created by Andrew Shepard on 3/19/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Cocoa
import Combine

extension NSOpenPanel {
    static func show(_ window: NSWindow, allowedFileTypes: [String]? = nil) -> Future<[URL], Never> {
        return Future<[URL], Never> { promise in
            let panel = NSOpenPanel()
            panel.canChooseFiles = true
            panel.allowsMultipleSelection = true
            panel.canChooseDirectories = false
            panel.canCreateDirectories = false
            panel.allowedFileTypes = allowedFileTypes
            
            panel.beginSheetModal(for: window) { (response) in
                promise(.success(panel.urls))
            }
        }
    }
}
