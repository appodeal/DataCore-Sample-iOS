//
//  HSAppConfiguration.swift
//  HolisticSolutionSDK
//
//  Created by Stas Kochkin on 25.06.2020.
//  Copyright © 2020 com.appodeal. All rights reserved.
//

import Foundation
import Appodeal


public let kHSAppDefaultTimeout: TimeInterval = 30.0

@objc(HSAppConfiguration) public final
class AppConfiguration: NSObject {
    @objc(HSAppConfigurationDebug) public
    enum Debug: Int {
        case system
        case enabled
        case disabled
    }

    internal let id: String = UUID().uuidString
    internal let appKey: String
    internal let timeout: TimeInterval
    internal let debug: Debug
    internal let adTypes: AppodealAdType
    
    @objc public
    init(
        appKey: String,
        timeout: TimeInterval = kHSAppDefaultTimeout,
        debug: Debug = .system,
        adTypes: AppodealAdType = [.banner, .interstitial, .MREC, .rewardedVideo]
    ) {
        self.appKey = appKey
        self.timeout = timeout
        self.debug = debug
        self.adTypes = adTypes
        super.init()
    }
}

internal extension AppConfiguration.Debug {
    func log(_ message: String) {
        switch self {
        case .enabled:
            NSLog("[HSApp] \(message)")
        case .system:
            #if DEBUG
            NSLog("[HSApp] \(message)")
            #endif
        default:
            break
        }
    }
}

