//
//  ToolbarViewModel.swift
//  AudioPlayer
//
//  Created by Andrew Shepard on 3/22/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Cocoa
import Combine

final class ToolbarViewModel {
    
    lazy var songTilePublisher: AnyPublisher<String?, Never> = {
        return controller.audioInfoPublisher
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }()
    
    lazy var progressPublisher: AnyPublisher<NSNumber, Never> = {
        return controller.progressPublisher
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }()
    
    private let controller: PlaybackController
    private var cancellables: [AnyCancellable] = []
    
    init(controller: PlaybackController) {
        self.controller = controller
    }
}
