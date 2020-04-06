//
//  ToolbarController.swift
//  AudioPlayer
//
//  Created by Andrew Shepard on 3/22/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Cocoa
import Combine

final class ToolbarController: NSObject {
        
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet weak var stopButton: NSButton!
    @IBOutlet weak var playbackControls: NSSegmentedControl!
    
    @IBOutlet private weak var progressWrapperView: NSView!
    @IBOutlet private weak var progressBar: NSProgressIndicator!
    @IBOutlet private weak var progressLabel: NSTextField!
    
    private var cancellables: [AnyCancellable] = []
    
    override init() {
        super.init()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        progressBar.minValue = 0.0
        progressBar.maxValue = 1.0
        
        progressLabel.stringValue = ""
    }
    
    var viewModel: ToolbarViewModel! {
        didSet {
            cancellables = []
            bindToViewModel()
        }
    }
    
    private func bindToViewModel() {
        viewModel.songTilePublisher
            .sink { [weak self] (title) in
                self?.progressLabel.stringValue = title ?? ""
            }
            .store(in: &cancellables)
        
        viewModel.progressPublisher
            .sink { [weak self] (progress) in
                self?.progressBar.doubleValue = progress.doubleValue
            }
            .store(in: &cancellables)
    }
}
