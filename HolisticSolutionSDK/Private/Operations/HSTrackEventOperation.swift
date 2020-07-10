//
//  HSTrackEventOperation.swift
//  HolisticSolutionSDK
//
//  Created by Stas Kochkin on 01.07.2020.
//  Copyright © 2020 com.appodeal. All rights reserved.
//

import Foundation

final class HSTrackEventOperation: HSAsynchronousOperation {
    private let analytics: [HSAnalyticsService]
    private let event: String
    private let params: [String: Any]?
    private let debug: HSAppConfiguration.Debug
    
    init(configuration: HSAppConfiguration,
         event: String,
         params: [String: Any]?) {
        self.analytics = configuration.analytics
        self.event = event
        self.params = params
        self.debug = configuration.debug
        super.init()
    }
    
    override func main() {
        super.main()
        debug.log("Track event")
        analytics.forEach { $0.trackEvent(event, customParameters: params) }
        finish()
    }
}
