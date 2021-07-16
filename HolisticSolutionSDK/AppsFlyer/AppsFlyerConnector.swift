//
//  AppsFlyerConnector.swift
//  HolisticSolutionSDK
//
//  Created by Stas Kochkin on 25.06.2020.
//  Copyright © 2020 com.appodeal. All rights reserved.
//

import Foundation
import UIKit
import AppsFlyerLib


@objc(HSAppsFlyerConnector) public final
class AppsFlyerConnector: NSObject, Service {
    private struct Parameters {
        var devKey, appId: String
        var conversionKeys: [String]
        var tracking: Bool
        
        init?(_ parameters: RawParameters) {
            guard
                let devKey = parameters["dev_key"] as? String,
                let appId = parameters["app_id"] as? String,
                let conversionKeys = parameters["conversion_keys"] as? [String],
                let tracking = parameters["tracking"] as? Bool
            else {
                return nil
            }
            
            self.devKey = devKey
            self.appId = appId
            self.conversionKeys = conversionKeys
            self.tracking = tracking
        }
    }
    
    public let name: String = "appsflyer"
    public let sdkVersion: String = AppsFlyerLib.shared().getSDKVersion()
    public var version: String { sdkVersion + ".1" }
    
    private var onReceiveConversionData: (([AnyHashable : Any]?) -> Void)?
    private var conversionKeys: [String] = []
    private var trackingEnabled = false
    
    @objc private
    func didBecomeActive(notification: Notification) {
        AppsFlyerLib.shared().start()
    }
    
    public func set(debug: AppConfiguration.Debug) {
        switch debug {
        case .disabled: AppsFlyerLib.shared().isDebug = false
        case .enabled: AppsFlyerLib.shared().isDebug = true
        case .system:
            #if DEBUG
            AppsFlyerLib.shared().isDebug = true
            #else
            AppsFlyerLib.shared().isDebug = false
            #endif
        }
    }
}


extension AppsFlyerConnector: RawParametersInitializable {
    func initialize(
        _ parameters: RawParameters,
        completion: @escaping (HSError?) -> ()
    ) {
        guard let parameters = Parameters(parameters) else {
            completion(.service("Unable to decode AppsFlyer parameters"))
            return
        }
        
        AppsFlyerLib.shared().appsFlyerDevKey = parameters.devKey
        AppsFlyerLib.shared().appleAppID = parameters.appId
        AppsFlyerLib.shared().delegate = self
        
        conversionKeys = parameters.conversionKeys
        trackingEnabled = parameters.tracking
        
        completion(nil)
    }
}


extension AppsFlyerConnector: AttributionService {
    func collect(
        receiveAttributionId: @escaping ((String) -> Void),
        receiveData: @escaping (([AnyHashable : Any]?) -> Void)
    ) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didBecomeActive(notification:)),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        onReceiveConversionData = receiveData
        
        AppsFlyerLib.shared().start()
        receiveAttributionId(AppsFlyerLib.shared().getAppsFlyerUID())
    }
    
    func validateAndTrackInAppPurchase(
        _ purchase: Purchase,
        success: (([AnyHashable : Any]) -> Void)?,
        failure: ((Error?, Any?) -> Void)?
    ) {
        AppsFlyerLib.shared().validateAndLog(
            inAppPurchase: purchase.productId,
            price: purchase.price,
            currency: purchase.currency,
            transactionId: purchase.transactionId,
            additionalParameters: purchase.additionalParameters,
            success: success,
            failure: failure
        )
    }
}


extension AppsFlyerConnector: AppsFlyerLibDelegate {
    public
    func onConversionDataSuccess(_ conversionInfo: [AnyHashable : Any]) {
        let data = conversionKeys.count > 0 ?
            conversionInfo.filter { pair in (pair.key as? String).map(conversionKeys.contains) ?? false } :
            conversionInfo
        DispatchQueue.main.async { [weak self] in
            self?.onReceiveConversionData?(data)
            self?.onReceiveConversionData = nil
        }
    }
    
    public
    func onConversionDataFail(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.onReceiveConversionData?(nil)
            self?.onReceiveConversionData = nil
        }
    }
}


extension AppsFlyerConnector: AnalyticsService {
    func trackEvent(_ event: String, customParameters: [String : Any]?) {
        guard trackingEnabled else { return }
        AppsFlyerLib.shared().logEvent(event, withValues: customParameters)
    }

    //MARK: - Noop
    func trackInAppPurchase(_ purchase: Purchase) {}
}
