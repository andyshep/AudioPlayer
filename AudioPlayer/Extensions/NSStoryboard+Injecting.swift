//
//  NSStoryboard+Injecting.swift
//  AudioPlayer
//
//  Created by Andrew Shepard on 3/21/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Cocoa

extension NSStoryboard {
    func instantiateViewController<Controller>(identifier: String, creator: ((NSCoder) -> Controller?)? = nil) -> Controller where Controller : NSViewController {
        instantiateController(
            identifier: NSStoryboard.SceneIdentifier.init(identifier),
            creator: creator
        )
    }
}
