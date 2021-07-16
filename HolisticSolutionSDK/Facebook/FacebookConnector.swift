//
//  FacebookConnector.swift
//  HolisticSolutionSDK
//
//  Created by Stas Kochkin on 01.07.2020.
//  Copyright © 2020 com.appodeal. All rights reserved.
//

import Foundation
import FBSDKCoreKit


@objc(HSFacebookConnector) public final
class FacebookConnector: NSObject, Service {
    struct Parameters {
        var tracking: Bool
        
        init(tracking: Bool = false) {
            self.tracking = tracking
        }
        
        init?(_ parameters: RawParameters) {
            guard let tracking = parameters["tracking"] as? Bool else { return nil }
            self.tracking = tracking
        }
    }
    
    public var name: String { "facebook" }
    public var sdkVersion: String { FBSDK_VERSION_STRING }
    public var version: String { sdkVersion + ".1" }
    
    private var parameters = Parameters()
    private weak var application: UIApplication?
    private var launchOptions: [UIApplication.LaunchOptionsKey : Any]?
    
    public func set(
        _ app: UIApplication,
        launchOptions: [UIApplication.LaunchOptionsKey : Any]?
    ) {
        self.application = app
        self.launchOptions = launchOptions
    }
}


extension FacebookConnector: RawParametersInitializable {
    func initialize(_ parameters: RawParameters, completion: @escaping (HSError?) -> ()) {
        guard
            let parameters = Parameters(parameters),
            validatePlist()
        else {
            completion(.service("Application's plist doesn't contain FacebookAppID"))
            return
        }
        
        self.parameters = parameters
        ApplicationDelegate.shared.application(
            application ?? .shared,
            didFinishLaunchingWithOptions: launchOptions
        )
        completion(nil)
    }
    
    private func validatePlist() -> Bool {
        let bundle = Bundle.main
        let appId = bundle.object(forInfoDictionaryKey:"FacebookAppID") as? String
        return appId != nil
    }
}

extension FacebookConnector: AnalyticsService {
    func trackEvent(_ event: String, customParameters: [String : Any]?) {
        guard parameters.tracking else { return }
        let name = AppEvents.Name(event)
        if let params = customParameters {
            AppEvents.logEvent(name, parameters: params)
        } else {
            AppEvents.logEvent(name)
        }
    }

    // MARK: - Noop
    func trackInAppPurchase(_ purchase: Purchase) {}
}
