//
//  NSButton+Combine.swift
//  AudioPlayer
//
//  Created by Andrew Shepard on 3/18/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Cocoa
import Combine

final class NSButtonSubscription<SubscriberType: Subscriber>: NSObject, Subscription where SubscriberType.Input == Void {
    private var subscriber: SubscriberType?
    private let button: NSButton
    
    init(subscriber: SubscriberType, button: NSButton) {
        self.subscriber = subscriber
        self.button = button
        
        super.init()
    }
    
    func request(_ demand: Subscribers.Demand) {
        button.action = #selector(NSButtonSubscription.handleButtonTap(_:))
        button.target = self
    }
    
    func cancel() {
        subscriber = nil
    }
    
    // MARK: Actions
    
    @objc func handleButtonTap(_ sender: Any) {
        _ = subscriber?.receive(())
    }
}

struct NSButtonPublisher: Publisher {
    typealias Output = Void
    typealias Failure = Never
    
    private let button: NSButton
    
    init(button: NSButton) {
        self.button = button
    }
    
    func receive<S>(subscriber: S) where S : Subscriber, NSButtonPublisher.Failure == S.Failure, NSButtonPublisher.Output == S.Input {
        let subscription = NSButtonSubscription(
            subscriber: subscriber,
            button: button
        )
        subscriber.receive(subscription: subscription)
    }
}

extension NSButton {
    var publisher: NSButtonPublisher {
        return NSButtonPublisher(button: self)
    }
}
