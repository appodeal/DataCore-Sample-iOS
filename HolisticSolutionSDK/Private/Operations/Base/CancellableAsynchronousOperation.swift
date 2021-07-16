//
//  HSCancellableAsynchronousOperation.swift
//  HolisticSolutionSDK
//
//  Created by Stas Kochkin on 29.06.2020.
//  Copyright © 2020 com.appodeal. All rights reserved.
//

import Foundation


/// Subclass of `HSAsynchronousOperation` that adds timeout on async action
/// 1. Call `super.main()` when override `main` method.
/// 2. When operation is finished or cancelled set `state = .finished` or `finish()`
/// Based on https://gist.github.com/Sorix/57bc3295dc001434fe08acbb053ed2bc
internal class CancellableAsynchronousOperation: AsynchronousOperation, ErrorProvider {
    private let timeout: TimeInterval
    
    private var timer: Timer?
    var error: HSError?

    init(timeout: TimeInterval) {
        self.timeout = timeout
        super.init()
    }
    
    override func main() {
        super.main()
        guard timer == nil else { return }
        let timer = Timer(
            timeInterval: timeout,
            target: self,
            selector: #selector(didFire(timer:)),
            userInfo: nil,
            repeats: false
        )
        timer.tolerance = timeout / 10
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
    
    @objc private func didFire(timer: Timer) {
        guard isExecuting else { return }
        error = .timeout("Execution exceeds limit: \(timeout)s")
        finish()
    }
    
    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    override func finish() {
        super.finish()
        invalidateTimer()
    }
    
    override func cancel() {
        super.cancel()
        invalidateTimer()
    }
    
    deinit {
        invalidateTimer()
    }
}
