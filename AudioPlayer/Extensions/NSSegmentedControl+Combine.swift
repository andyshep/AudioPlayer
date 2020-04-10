//
//  NSSegmentedControl+Combine.swift
//  AudioPlayer
//
//  Created by Andrew Shepard on 3/22/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Cocoa
import Combine

final class NSSegmentedControlSubscription<SubscriberType: Subscriber>: NSObject, Subscription where SubscriberType.Input == Int {
    private var subscriber: SubscriberType?
    private let control: NSSegmentedControl
    
    init(subscriber: SubscriberType, control: NSSegmentedControl) {
        self.subscriber = subscriber
        self.control = control
        
        super.init()
    }
    
    func request(_ demand: Subscribers.Demand) {
        control.action = #selector(NSSegmentedControlSubscription.handleSegmentIndex(_:))
        control.target = self
    }
    
    func cancel() {
        subscriber = nil
    }
    
    // MARK: Actions
    
    @objc func handleSegmentIndex(_ sender: Any) {
        print(control.selectedSegment)
        _ = subscriber?.receive(control.selectedSegment)
    }
}

struct NSSegmentedControlPublisher: Publisher {
    typealias Output = Int
    typealias Failure = Never
    
    private let control: NSSegmentedControl
    
    init(control: NSSegmentedControl) {
        self.control = control
    }
    
    func receive<S>(subscriber: S) where S : Subscriber, NSSegmentedControlPublisher.Failure == S.Failure, NSSegmentedControlPublisher.Output == S.Input {
        let subscription = NSSegmentedControlSubscription(
            subscriber: subscriber,
            control: control
        )
        subscriber.receive(subscription: subscription)
    }
}

extension NSSegmentedControl {
    var publisher: NSSegmentedControlPublisher {
        return NSSegmentedControlPublisher(control: self)
    }
}
