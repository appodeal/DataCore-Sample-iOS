//
//  CompletionOperation.swift
//  HolisticSolutionSDK
//
//  Created by Stas Kochkin on 07.06.2021.
//  Copyright © 2021 com.appodeal. All rights reserved.
//

import Foundation


final class CompletionOperation: Operation {
    let block: ((Error?) -> ())?
    
    init(block: ((Error?) -> ())?) {
        self.block = block
        super.init()
    }
    
    override func main() {
        guard !isCancelled else { return }
        let error = dependencies
            .compactMap { $0 as? ErrorProvider }
            .compactMap { $0.error }
            .first
            .map { $0.nserror }
        App.log("Holistic Solution completed initialization")
        block?(error)
    }
}

internal extension HSError {
    var nserror: NSError { NSError.from(self) }
}

fileprivate extension NSError {
    static func from(_ error: HSError) -> NSError {
        let domain = "com.explorestack.hs"
        let userInfo: [String: Any]
        let code: Int
        switch error {
        case .integration(let description):
            code = 10
            userInfo = [
                NSLocalizedFailureReasonErrorKey: "Some of input paramerers was invalid",
                NSLocalizedDescriptionKey: description
            ]
        case .service(let description):
            code = 11
            userInfo = [
                NSLocalizedFailureReasonErrorKey: "Error has been occurred while starting service",
                NSLocalizedDescriptionKey: description
            ]
        case .timeout(let description):
            code = 12
            userInfo = [
                NSLocalizedFailureReasonErrorKey: "HSApp timeout has been reached",
                NSLocalizedDescriptionKey: description
            ]
        case .unknown(let description):
            code = 13
            userInfo = [
                NSLocalizedFailureReasonErrorKey: "Unknown error has been occurred",
                NSLocalizedDescriptionKey: description
            ]
        }
        
        return NSError(
            domain: domain,
            code: code,
            userInfo: userInfo
        )
    }
}
