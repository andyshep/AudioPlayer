//
//  PlaylistViewModel.swift
//  AudioPlayer
//
//  Created by Andrew Shepard on 3/21/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Cocoa
import Combine

final class PlaylistViewModel: NSObject {
    
    // MARK: Inputs
    
    var playEvent: AnySubscriber<Void, Never> {
        return AnySubscriber(playEventSubject)
    }
    private let playEventSubject = PassthroughSubject<Void, Never>()
    
    var stopEvent: AnySubscriber<Void, Never> {
        return AnySubscriber(stopEventSubject)
    }
    private let stopEventSubject = PassthroughSubject<Void, Never>()
    
    var trackForwardEvent: AnySubscriber<Void, Never> {
        return AnySubscriber(trackForwardSubject)
    }
    private let trackForwardSubject = PassthroughSubject<Void, Never>()
    
    var trackBackEvent: AnySubscriber<Void, Never> {
        return AnySubscriber(trackBackSubject)
    }
    private let trackBackSubject = PassthroughSubject<Void, Never>()
    
    var countPublisher: AnyPublisher<Int, Never> {
        return KeyValueObservingPublisher(
            object: arrayController,
            keyPath: \NSArrayController.arrangedObjects,
            options: []
        )
        .map { result -> Int in
            return (result as? [AudioFile])?.count ?? 0
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: Output
    
    lazy var arrayController: NSArrayController = {
        let controller = NSArrayController()
        controller.bind(.contentArray, to: self, withKeyPath: "audioFiles")
        return controller
    }()
    @objc private var audioFiles: [AudioFile] = []
    
    private let controller: PlaybackController
    private var cancellables: [AnyCancellable] = []
    
    init(controller: PlaybackController) {
        self.controller = controller
        super.init()
        
        bindToEvents()
    }
    
    func updatePlaylist(with urls: [URL]) {
        willChangeValue(for: \.audioFiles)
        audioFiles.append(contentsOf: urls.map { AudioFile(path: $0) })
        didChangeValue(for: \.audioFiles)
    }
    
    private func bindToEvents() {
        playEventSubject
            .eraseToAnyPublisher()
            .map { [unowned self] in
                let index = self.arrayController.selectionIndex
                return self.audioFiles[index]
            }
            .sink { [weak self] file in
                self?.controller.play(file: file)
            }
            .store(in: &cancellables)
        
        stopEventSubject
            .eraseToAnyPublisher()
            .sink { [weak self] _ in
                self?.controller.stop()
            }
            .store(in: &cancellables)
        
        trackBackSubject
            .eraseToAnyPublisher()
            .compactMap { [unowned self] _ -> AudioFile? in
                let index = self.arrayController.selectionIndex
                guard index >= 1 else { return nil }
                return self.audioFiles[index - 1]
            }
            .do(onNext: { [weak self] _ in
                self?.arrayController.selectPrevious(nil)
            })
            .sink { [weak self] (file) in
                self?.controller.play(file: file)
            }
            .store(in: &cancellables)
        
        trackForwardSubject
            .eraseToAnyPublisher()
            .compactMap { [unowned self] _ -> AudioFile? in
                let index = self.arrayController.selectionIndex
                guard index < self.audioFiles.count - 1 else { return nil }
                return self.audioFiles[index + 1]
            }
            .do(onNext: { [weak self] _ in
                self?.arrayController.selectNext(nil)
            })
            .sink { [weak self] (file) in
                self?.controller.play(file: file)
            }
            .store(in: &cancellables)
    }
}
