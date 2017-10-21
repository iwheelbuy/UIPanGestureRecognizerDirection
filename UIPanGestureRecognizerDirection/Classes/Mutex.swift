import Foundation

internal protocol ScopedMutex {

    func sync<R>(execute work: () throws -> R) rethrows -> R
    func trySync<R>(execute work: () throws -> R) rethrows -> R?
}

internal protocol RawMutex: ScopedMutex {
    
    associatedtype MutexPrimitive

    var unsafeMutex: MutexPrimitive { get set }
    
    func unbalancedLock()
    func unbalancedTryLock() -> Bool
    func unbalancedUnlock()
}

extension RawMutex {

    internal func sync<R>(execute work: () throws -> R) rethrows -> R {
        unbalancedLock()
        defer { unbalancedUnlock() }
        return try work()
    }
    
    internal func trySync<R>(execute work: () throws -> R) rethrows -> R? {
        guard unbalancedTryLock() else { return nil }
        defer { unbalancedUnlock() }
        return try work()
    }
}

internal final class PThreadMutex: RawMutex {
    
    internal typealias MutexPrimitive = pthread_mutex_t
    
    internal enum PThreadMutexType {
        case normal
        case recursive
    }
    
    internal var unsafeMutex = pthread_mutex_t()
    
    internal init(type: PThreadMutexType = .normal) {
        var attr = pthread_mutexattr_t()
        guard pthread_mutexattr_init(&attr) == 0 else {
            preconditionFailure()
        }
        switch type {
        case .normal:
            pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_NORMAL)
        case .recursive:
            pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE)
        }
        guard pthread_mutex_init(&unsafeMutex, &attr) == 0 else {
            preconditionFailure()
        }
    }
    
    deinit {
        pthread_mutex_destroy(&unsafeMutex)
    }
    
    internal func unbalancedLock() {
        pthread_mutex_lock(&unsafeMutex)
    }
    
    internal func unbalancedTryLock() -> Bool {
        return pthread_mutex_trylock(&unsafeMutex) == 0
    }
    
    internal func unbalancedUnlock() {
        pthread_mutex_unlock(&unsafeMutex)
    }
}
