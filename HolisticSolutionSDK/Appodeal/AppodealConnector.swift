//
//  HSAppodealConnector.swift
//  HolisticSolutionSDK
//
//  Created by Stas Kochkin on 26.06.2020.
//  Copyright © 2020 com.appodeal. All rights reserved.
//

import Foundation
import StackConsentManager
import Appodeal
import StackFoundation


@objc(HSAppodealConnector) final
class AppodealConnector: NSObject, Service {
    var name: String { "appodeal" }
    var sdkVersion: String { APDSdkVersionString() }
    var version: String { APDSdkVersionString() + ".1" }
    
    func set(debug: AppConfiguration.Debug) {
        switch debug {
        case .disabled: Appodeal.setLogLevel(.off)
        case .enabled: Appodeal.setLogLevel(.debug)
        case .system: Appodeal.setLogLevel(.error)
        }
    }
}


extension AppodealConnector: Advertising {
    func setTrackId(_ trackId: String) {
        DispatchQueue.main.async {
            Appodeal.setExtras(["track_id": trackId])
        }
    }
    
    public func setAttributionId(_ attributionId: String) {
        DispatchQueue.main.async {
            Appodeal.setExtras(["attribution_id": attributionId])
        }
    }
    
    public func setConversionData(_ converstionData: [AnyHashable : Any]) {
        Appodeal.setCustomState(converstionData)
    }
    
    public func setProductTestData(_ productTestData: [AnyHashable : Any]) {
        let keywords = productTestData.values.compactMap { $0 as? String }.joined(separator: ",")
        DispatchQueue.main.async {
            Appodeal.setExtras(["keywords": keywords])
        }
    }
    
    public func setMMP(mmp: String) {
        DispatchQueue.main.async {
            Appodeal.setExtras(["mmp":mmp])
        }
    }
}


extension AppodealConnector: Initializable {
    typealias Parameters = AppConfiguration
    
    func initialize(_ parameters: AppConfiguration, completion: @escaping (HSError?) -> ()) {
        defer { completion(nil) }
        if let consent = STKConsentManager.shared().consent {
            let selector = NSSelectorFromString("initializeWithApiKey:types:consentReport:")
            typealias InitializeType = @convention(c) (AnyObject, Selector, String, AppodealAdType, STKConsent) -> ()
            let method = Appodeal.method(for: selector)
            let initialize = unsafeBitCast(method, to: InitializeType.self)
            initialize(Appodeal.self, selector, parameters.appKey, parameters.adTypes, consent)
        } else {
            Appodeal.initialize(
                withApiKey: parameters.appKey,
                types: parameters.adTypes
            )
        }
    }
}


extension AppodealConnector: AnalyticsService {
    func trackInAppPurchase(_ purchase: Purchase) {
        DispatchQueue.main.async {
            Appodeal.track(
                inAppPurchase: purchase.priceValue(),
                currency: purchase.currency
            )
        }
    }
    
    func trackEvent(_ event: String, customParameters: [String : Any]?) {}
}


fileprivate extension Purchase {
    func priceValue() -> NSNumber {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        if let number = formatter.number(from: price) {
            return number
        } else {
            let pattern = #"(\d.)+"#
            // Remove spaces and replace comma with dot
            let withoutSpaces = price
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: ",", with: ".")
            // Search numbers
            guard let range = withoutSpaces.range(of:pattern, options: .regularExpression)
            else { return 0 }
            // Search whole and fractional parts
            let result = String(withoutSpaces[range]).components(separatedBy: ".")
            let fractionalPart = result.last ?? "00"
            let wholePart  = result.dropLast().joined()
            let raw = wholePart.appending(".").appending(fractionalPart)
            // Try to parse it again
            let number = formatter.number(from: raw)
            return number ?? 0
        }
    }
}
