//
//  HSCompletionOperation.swift
//  HolisticSolutionSDK
//
//  Created by Stas Kochkin on 30.06.2020.
//  Copyright © 2020 com.appodeal. All rights reserved.
//

import Foundation


internal protocol HSErrorProvider {
    var error: HSError? { get }
}

internal class HSCompletionOperation: Operation {
    typealias Completion = (NSError?) -> Void
    
    private let completion: Completion?
    
    init(_ completion: Completion?) {
        self.completion = completion
        super.init()
    }
    
    override func start() {
        guard !isCancelled else { return }
        let errors = dependencies
            .compactMap { $0 as? HSErrorProvider }
            .compactMap { $0.error }
        let error = errors.count == dependencies.count ? errors.first : nil
        DispatchQueue.main.async { [unowned self] in self.completion?(error.map { $0.nserror }) }
    }
}
