//
//  AsynchronousOperation.swift
//  HolisticSolutionSDK
//
//  Created by Stas Kochkin on 25.06.2020.
//  Copyright © 2020 com.appodeal. All rights reserved.
//

import Foundation

/// Subclass of `Operation` that adds support of asynchronous operations.
/// 1. Call `super.main()` when override `main` method.
/// 2. When operation is finished or cancelled set `state = .finished` or `finish()`
/// Based on https://gist.github.com/Sorix/57bc3295dc001434fe08acbb053ed2bc
internal class AsynchronousOperation: Operation {
    // MARK: - State management
    enum State: String {
        case ready = "Ready"
        case executing = "Executing"
        case finished = "Finished"
        
        fileprivate var keyPath: String { return "is" + self.rawValue }
        fileprivate var isExcecuting: Bool { return self == .executing }
        fileprivate var isFinished: Bool { return self == .finished }
    }
    
    override var isAsynchronous: Bool { return true }
    override var isExecuting: Bool { return state.isExcecuting }
    override var isFinished: Bool { return state.isFinished }
    
    override func start() {
        if isCancelled {
            state = .finished
        } else {
            state = .ready
            main()
        }
    }
    
    open override func main() {
        if isCancelled {
            state = .finished
        } else {
            state = .executing
        }
    }
    
    func finish() {
        state = .finished
    }
    
    var state: State {
        get {
            stateQueue.sync { return stateStore }
        }
        set {
            let oldValue = state
            willChangeValue(forKey: state.keyPath)
            willChangeValue(forKey: newValue.keyPath)
            stateQueue.sync(flags: .barrier) { stateStore = newValue }
            didChangeValue(forKey: state.keyPath)
            didChangeValue(forKey: oldValue.keyPath)
        }
    }
    
    private let stateQueue = DispatchQueue(label: "com.hsoperation.queue",
                                           attributes: .concurrent)
    private var stateStore: State = .ready
}
