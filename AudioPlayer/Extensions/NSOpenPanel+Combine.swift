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
//    func showAndCompletion(_ window: NSWindow) -> Future<NSApplication.ModalResponse, Never> {
//        return Future<NSApplication.ModalResponse, Never> { [unowned self] promise in
//            self.beginSheetModal(for: window) { (response) in
//                promise(.success(response))
//            }
//        }
//    }
    
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
