//
//  NSArrayController+Combine.swift
//  AudioPlayer
//
//  Created by Andrew Shepard on 3/19/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Cocoa
import Combine

extension NSArrayController {
    var selectionIndexPublisher: AnyPublisher<Int, Never> {
        return KeyValueObservingPublisher(
            object: self,
            keyPath: \.selectionIndex,
            options: [.new]
        )
        .eraseToAnyPublisher()
    }
    
    var arrangedObjectsPublisher: AnyPublisher<Any, Never> {
        return KeyValueObservingPublisher(
            object: self,
            keyPath: \.arrangedObjects,
            options: [.initial, .new]
        )
        .eraseToAnyPublisher()
    }
}
