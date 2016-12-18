//
//  PublishSubject.swift
//  RxSwift
//
//  Created by Krunoslav Zaher on 2/11/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation

/// Represents an object that is both an observable sequence as well as an observer.
///
/// Each notification is broadcasted to all subscribed observers.
final public class PublishSubject<Element>
    : Observable<Element>
    , SubjectType
    , Cancelable
    , ObserverType
    , SynchronizedUnsubscribeType {
    public typealias SubjectObserverType = PublishSubject<Element>
    
    typealias DisposeKey = Bag<AnyObserver<Element>>.KeyType
    
    /// Indicates whether the subject has any observers
    public var hasObservers: Bool {
        lock(_lock)
        let count = _observers.count > 0
        unlock(_lock)
        return count
    }
    
    private var _lock = createLock()
    
    // state
    private var _isDisposed = false
    private var _observers = Bag<(Event<Element>) -> ()>()
    private var _stopped = false
    private var _stoppedEvent = nil as Event<Element>?
    
    /// Indicates whether the subject has been isDisposed.
    public var isDisposed: Bool {
        return _isDisposed
    }
    
    /// Creates a subject.
    public override init() {
        super.init()
    }
    
    /// Notifies all subscribed observers about next event.
    ///
    /// - parameter event: Event to send to the observers.
    public func on(_ event: Event<Element>) {
        lock(_lock)
        dispatch(_synchronized_on(event), event)
        unlock(_lock)
    }

    func _synchronized_on(_ event: Event<E>) -> Bag<(Event<Element>) -> ()> {
        switch event {
        case .next(_):
            if _isDisposed || _stopped {
                return Bag()
            }
            
            return _observers
        case .completed, .error:
            if _stoppedEvent == nil {
                _stoppedEvent = event
                _stopped = true
                let observers = _observers
                _observers.removeAll()
                return observers
            }

            return Bag()
        }
    }
    
    /**
    Subscribes an observer to the subject.
    
    - parameter observer: Observer to subscribe to the subject.
    - returns: Disposable object that can be used to unsubscribe the observer from the subject.
    */
    public override func subscribe<O : ObserverType>(_ observer: O) -> Disposable where O.E == Element {
        lock(_lock)
        let subscription = _synchronized_subscribe(observer)
        unlock(_lock)
        return subscription
    }

    func _synchronized_subscribe<O : ObserverType>(_ observer: O) -> Disposable where O.E == E {
        if let stoppedEvent = _stoppedEvent {
            observer.on(stoppedEvent)
            return Disposables.create()
        }
        
        if _isDisposed {
            observer.on(.error(RxError.disposed(object: self)))
            return Disposables.create()
        }
        
        let key = _observers.insert(observer.on)
        return SubscriptionDisposable(owner: self, key: key)
    }

    func synchronizedUnsubscribe(_ disposeKey: DisposeKey) {
        lock(_lock)
        _synchronized_unsubscribe(disposeKey)
        unlock(_lock)
    }

    func _synchronized_unsubscribe(_ disposeKey: DisposeKey) {
        _ = _observers.removeKey(disposeKey)
    }
    
    /// Returns observer interface for subject.
    public func asObserver() -> PublishSubject<Element> {
        return self
    }
    
    /// Unsubscribe all observers and release resources.
    public func dispose() {
        lock(_lock)
        _synchronized_dispose()
        unlock(_lock)
    }

    final func _synchronized_dispose() {
        _isDisposed = true
        _observers.removeAll()
        _stoppedEvent = nil
    }
}
