//
//  NSTableView+Combine.swift
//  AudioPlayer
//
//  Created by Andrew Shepard on 4/5/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Cocoa
import Combine

final class NSTableViewSubscription<SubscriberType: Subscriber>: NSObject, Subscription where SubscriberType.Input == Void {
    private var subscriber: SubscriberType?
    private let tableView: NSTableView
    
    init(subscriber: SubscriberType, tableView: NSTableView) {
        self.subscriber = subscriber
        self.tableView = tableView
        
        super.init()
    }
    
    func request(_ demand: Subscribers.Demand) {
        tableView.doubleAction = #selector(NSTableViewSubscription.handleDoubleClick(_:))
        tableView.target = self
    }
    
    func cancel() {
        subscriber = nil
    }
    
    // MARK: Actions
    
    @objc func handleDoubleClick(_ sender: Any) {
        _ = subscriber?.receive(())
    }
}

struct NSTableViewPublisher: Publisher {
    typealias Output = Void
    typealias Failure = Never
    
    private let tableView: NSTableView
    
    init(tableView: NSTableView) {
        self.tableView = tableView
    }
    
    func receive<S>(subscriber: S) where S : Subscriber, NSTableViewPublisher.Failure == S.Failure, NSTableViewPublisher.Output == S.Input {
        let subscription = NSTableViewSubscription(
            subscriber: subscriber,
            tableView: tableView
        )
        subscriber.receive(subscription: subscription)
    }
}

extension NSTableView {
    var doubleClickPublisher: NSTableViewPublisher {
        return NSTableViewPublisher(tableView: self)
    }
}
