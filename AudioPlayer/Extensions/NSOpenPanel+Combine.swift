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
    func showAndCompletion() -> Future<NSApplication.ModalResponse, Never> {
        return Future<NSApplication.ModalResponse, Never> { [unowned self] promise in
            self.begin { (response) in
                promise(.success(response))
            }
        }
    }
}
