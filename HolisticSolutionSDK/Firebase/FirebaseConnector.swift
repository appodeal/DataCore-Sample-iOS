//
//  HSRemoteConfigConnector.swift
//  HolisticSolutionSDK
//
//  Created by Stas Kochkin on 26.06.2020.
//  Copyright © 2020 com.appodeal. All rights reserved.
//

import Foundation
import FirebaseCore
import FirebaseRemoteConfig
import FirebaseAnalytics


@objc(HSFirebaseConnector) public
final class FirebaseConnector: NSObject, Service {
    struct Parameters {
        var configKeys: [String]
        var expirationDuration: TimeInterval
        var tracking: Bool
        
        init(
            configKeys: [String] = [],
            expirationDuration: TimeInterval = 30,
            tracking: Bool = false
        ) {
            self.configKeys = configKeys
            self.expirationDuration = expirationDuration
            self.tracking = tracking
        }
            
        init?(_ parameters: RawParameters) {
            guard
                let configKeys = parameters["config_keys"] as? [String],
                let expirationDuration = parameters["expiration_duration"] as? TimeInterval,
                let tracking = parameters["tracking"] as? Bool
            else { return nil }
            
            self.configKeys = configKeys
            self.expirationDuration = expirationDuration
            self.tracking = tracking
        }
    }

    public var name: String { "firebase" }
    public var sdkVersion: String { FirebaseVersion() }
    public var version: String { sdkVersion + ".1" }
        
    public var onReceiveConfig: (([AnyHashable : Any]) -> Void)?
    
    private var parameters = Parameters()

    private lazy var config: RemoteConfig = {
        // Setup settings
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        // Config
        let config = RemoteConfig.remoteConfig()
        config.configSettings = settings
        return config
    }()
}

extension FirebaseConnector: RawParametersInitializable {
    func initialize(
        _ parameters: RawParameters,
        completion: @escaping (HSError?) -> ()
    ) {
        guard let parameters = Parameters(parameters) else {
            completion(.service("Unable to decode Firebase parameters"))
            return
        }
        
        self.parameters = parameters
        
        if let _ = FirebaseApp.allApps {
            completion(nil)
        } else {
            FirebaseApp.configure()
            completion(nil)
        }
    }
}


extension FirebaseConnector: ProductTestingService {
    func activateConfig(completion: @escaping (([AnyHashable : Any]?) -> Void)) {
        config.fetch(withExpirationDuration: parameters.expirationDuration) { [weak self] status, error in
            guard let self = self else { return }
            // Fallback on fetch failed
            guard status == .success, error == nil else {
                completion(nil)
                return
            }
            self.activate(completion)
        }
    }
    
    private func activate(_ completion: @escaping ([AnyHashable: Any]) -> ()) {
        // Activate config
        config.activate { [weak self] _, _ in
            guard let self = self else { return }
            // Transform config to Appodeal extras
            let config = self.getConfig()
            DispatchQueue.main.async { completion(config) }
        }
    }

    private func getConfig() -> [AnyHashable: Any] {
        let keys = parameters.configKeys.count > 0 ? parameters.configKeys : config.allKeys(from: .remote)
        return keys.reduce([:]) { result, key in
            var result = result
            if let value = config.configValue(forKey: key).stringValue {
                result[key] = value
            }
            return result
        }
    }
}


extension FirebaseConnector: AnalyticsService {
    func trackEvent(_ event: String, customParameters: [String : Any]?) {
        guard parameters.tracking else { return }
        Analytics.logEvent(event, parameters: customParameters)
    }
    
    //MARK: - Noop
    func trackInAppPurchase(_ purchase: Purchase) {}
}
