//
//  FastRecursiveLock.swift
//  Rx
//
//  Created by Krunoslav Zaher on 12/18/16.
//  Copyright © 2016 Krunoslav Zaher. All rights reserved.
//

import Foundation

/*
open class NSRecursiveLock: NSObject, NSLocking {
    #if CYGWIN
    internal var mutex = UnsafeMutablePointer<pthread_mutex_t?>.allocate(capacity: 1)
    #else
    internal var mutex = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
    #endif

    public override init() {
        super.init()
        #if CYGWIN
            var attrib : pthread_mutexattr_t? = nil
        #else
            var attrib = pthread_mutexattr_t()
        #endif
        withUnsafeMutablePointer(to: &attrib) { attrs in
            pthread_mutexattr_settype(attrs, Int32(PTHREAD_MUTEX_RECURSIVE))
            pthread_mutex_init(mutex, attrs)
        }
    }

    deinit {
        pthread_mutex_destroy(mutex)
        mutex.deinitialize()
        mutex.deallocate(capacity: 1)
    }

    open func lock() {
        pthread_mutex_lock(mutex)
    }

    open func unlock() {
        pthread_mutex_unlock(mutex)
    }

    open func `try`() -> Bool {
        return pthread_mutex_trylock(mutex) == 0
    }

    open func lock(before limit: Date) {
        NSUnimplemented()
    }
    
    open var name: String?
}*/

typealias FastRecursiveLock = UnsafeMutablePointer<pthread_mutex_t>

func createLock() -> FastRecursiveLock {
    #if CYGWIN
    let mutex = UnsafeMutablePointer<pthread_mutex_t?>.allocate(capacity: 1)
    #else
    let mutex = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
    #endif
    
    #if CYGWIN
        var attrib : pthread_mutexattr_t? = nil
    #else
        var attrib = pthread_mutexattr_t()
    #endif
    withUnsafeMutablePointer(to: &attrib) { attrs in
        pthread_mutexattr_settype(attrs, Int32(PTHREAD_MUTEX_RECURSIVE))
        pthread_mutex_init(mutex, attrs)
    }
    return mutex
}

@inline(__always)
func lock(_ mutex: FastRecursiveLock) {
    pthread_mutex_lock(mutex)
}

@inline(__always)
func unlock(_ mutex: FastRecursiveLock) {
    pthread_mutex_unlock(mutex)
}

@inline(__always)
func releaseLock(_ mutex: FastRecursiveLock) {
    pthread_mutex_destroy(mutex)
    mutex.deinitialize()
    mutex.deallocate(capacity: 1)
}
