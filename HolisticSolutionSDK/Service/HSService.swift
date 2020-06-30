//
//  HSService.swift
//  HolisticSolutionSDK
//
//  Created by Stas Kochkin on 30.06.2020.
//  Copyright © 2020 com.appodeal. All rights reserved.
//

import Foundation


@objc public
protocol HSService {
    func initialise(success: @escaping () -> Void,
                    failure: @escaping (HSError) -> Void)
    
    func setDebug(_ debug: HSAppConfiguration.Debug)
}

@objc public
protocol HSAttributionService: HSService {
    var onReceiveAttributionId: ((String) -> Void)? { get set }
    var onReceiveData: (([AnyHashable: Any]) -> Void)? { get set }
}

@objc public protocol HSProductTestingService: HSService {
    var onReceiveConfig: (([AnyHashable: Any]) -> Void)? { get set }
}

