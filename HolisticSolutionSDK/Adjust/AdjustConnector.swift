//
//  AdjustConnector.swift
//  HolisticSolutionSDK
//
//  Created by Stas Kochkin on 13.05.2021.
//  Copyright © 2021 com.appodeal. All rights reserved.
//

import Foundation
import UIKit
import Adjust
import AdjustPurchase
import StackFoundation


@objc(HSAdjustConnector) public final
class AdjustConnector: NSObject, Service {
    private static let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.generatesDecimalNumbers = true
        return formatter
    }()
    
    fileprivate struct FallbackInfo {
        var event: EventKey
        var message: String
    }
    
    fileprivate enum EventKey: RawRepresentable {
        typealias RawValue = String
        
        case unknown
        case purchase
        case custom(String)
        
        init?(rawValue: String) {
            switch rawValue {
            case "Unknown": self = .unknown
            case "Purchase": self = .purchase
            default: self = .custom(rawValue)
            }
        }
        
        var rawValue: String {
            switch self {
            case .purchase: return "Purchase"
            case .unknown: return "Unknown"
            case .custom(let value): return value
            }
        }
    }
    
    struct Parameters {
        var appToken, environment: String
        var tracking: Bool
        private var events: [String: String]
        
        init(
            appToken: String = "",
            environment: String = "sandbox",
            tracking: Bool = false,
            events: [String: String] = [:]
        ) {
            self.appToken = appToken
            self.environment = environment
            self.tracking = tracking
            self.events = events
        }
        
        init?(_ parameters: RawParameters) {
            guard
                let appToken = parameters["app_token"] as? String,
                let environment = parameters["environment"] as? String,
                let tracking = parameters["tracking"] as? Bool
            else { return nil }
            
            let events = parameters["events"] as? [String: String] ?? [:]
            
            self.init(
                appToken: appToken,
                environment: environment,
                tracking: tracking,
                events: events
            )
        }
        
        fileprivate func token(for event: EventKey) -> String? {
            return events[event.rawValue]
        }
    }
    
    public var name: String { "adjust" }
    public var sdkVersion: String { Adjust.sdkVersion() ?? "" }
    public var version: String { sdkVersion + ".1" }
    public var onReceiveConversionData: (([AnyHashable : Any]?) -> Void)?
    
    private var onCompleteInitialization: ((HSError?) -> ())?
    private var parameters = Parameters()
    private var debug: AppConfiguration.Debug = .system
    
    public func set(debug: AppConfiguration.Debug) {
        self.debug = debug
    }
}

// MARK: Protocols
extension AdjustConnector: RawParametersInitializable {
    func initialize(
        _ parameters: RawParameters,
        completion: @escaping (HSError?) -> ()
    ) {
        guard let parameters = Parameters(parameters) else {
            completion(.service("Unable to decode Adjust parameters"))
            return
        }
        
        self.parameters = parameters
        self.onCompleteInitialization = completion
        
        let config = ADJConfig(
            appToken: parameters.appToken,
            environment: parameters.environment
        )
        
        config?.delegate = self
        switch debug {
        case .enabled: config?.logLevel = ADJLogLevelVerbose
        case .disabled: config?.logLevel = ADJLogLevelSuppress
        default: break
        }
        
        if STKAd.isZeroIDFA {
            config?.externalDeviceId = STKAd.generatedAdvertisingIdentifier
        }
        
        Adjust.addSessionCallbackParameter("externalDeviceId", value: STKAd.generatedAdvertisingIdentifier)
        
        Adjust.appDidLaunch(config)
        
        let purchaseConfig = ADJPConfig(
            appToken: parameters.appToken,
            andEnvironment: parameters.environment
        )
        
        switch debug {
        case .enabled: purchaseConfig?.logLevel = ADJPLogLevelVerbose
        case .disabled: purchaseConfig?.logLevel = ADJPLogLevelNone
        default: break
        }
        
        AdjustPurchase.`init`(purchaseConfig)
        
        if let _ = Adjust.adid() {
            self.onCompleteInitialization = nil
            completion(nil)
        }
    }
}


extension AdjustConnector: AttributionService {
    func collect(receiveAttributionId: @escaping ((String) -> Void), receiveData: @escaping (([AnyHashable : Any]?) -> Void)) {
        Adjust.adid().map(receiveAttributionId)
        Adjust.attribution().flatMap { $0.dictionary() }.map(receiveData)
        onReceiveConversionData = receiveData
    }
    
    func validateAndTrackInAppPurchase(
        _ purchase: Purchase,
        success: (([AnyHashable : Any]) -> Void)?,
        failure: ((Error?, Any?) -> Void)?
    ) {
        guard let reciept = Bundle.main.receipt else {
            failure?(HSError.unknown("No app store receipt url was found").nserror, nil)
            return
        }
        
        guard
            let transaction = SKPaymentQueue
                .default()
                .transactions
                .first(where: { $0.transactionIdentifier == purchase.transactionId })
        else {
            failure?(HSError.unknown("Transaction was not found").nserror, nil)
            return
        }
        
        AdjustPurchase.verifyPurchase(
            reciept,
            forTransaction: transaction,
            productId: purchase.productId
        ) { [weak self] info in
            guard
                let info = info,
                info.verificationState == ADJPVerificationStatePassed
            else {
                failure?(HSError.service("Purchase was't passed verification"), nil)
                return
            }
            self?.trackInAppPurchase(purchase)
            success?(["message": info.message].compactMapValues { $0 })
        }
    }
}


extension AdjustConnector: AdjustDelegate {
    public
    func adjustSessionTrackingSucceeded(_ sessionSuccessResponseData: ADJSessionSuccess?) {
        onCompleteInitialization?(nil)
        onCompleteInitialization = nil
    }
    
    public
    func adjustEventTrackingFailed(_ eventFailureResponseData: ADJEventFailure?) {
        let message = eventFailureResponseData?.message ?? "Unknown adjust initialization"
        onCompleteInitialization?(.service(message))
        onCompleteInitialization = nil
    }
    
    public
    func adjustAttributionChanged(_ attribution: ADJAttribution?) {
        onCompleteInitialization?(nil)
        onCompleteInitialization = nil
        attribution
            .flatMap { $0.dictionary() }
            .map {
                onReceiveConversionData?($0)
                onReceiveConversionData = nil
            }
    }
}


extension AdjustConnector: AnalyticsService {
    func trackEvent(_ event: String, customParameters: [String : Any]?) {
        guard parameters.tracking else { return }
        
        guard let token = parameters.token(for: .custom(event)) else {
            fallback(.init(event: .custom(event), message: "Token was not found"))
            return
        }
        
        let adjEvent = ADJEvent(
            token: token,
            parameters: customParameters
        )
        
        Adjust.trackEvent(adjEvent)
    }
    
    func trackInAppPurchase(_ purchase: Purchase) {
        switch purchase.type {
        case .consumable, .nonConsumable: _trackInAppPurchase(purchase)
        case .autoRenewableSubscription, .nonRenewingSubscription: _trackSubscription(purchase)
        }
    }
    
    private func _trackInAppPurchase(_ purchase: Purchase) {
        guard let token = parameters.token(for: .purchase) else {
            fallback(.init(event: .purchase, message: "Token was not found"))
            return
        }
        
        guard let receipt = Bundle.main.receipt else {
            fallback(.init(event: .purchase, message: "AppStore receipt was not found"))
            return
        }
        
        guard let price = AdjustConnector.priceFormatter.number(from: purchase.price) as? NSDecimalNumber else {
            fallback(.init(event: .purchase, message: "Unable to serialize price \(purchase.price)"))
            return
        }
        
        let event = ADJEvent(eventToken: token)
        event?.setRevenue(price.doubleValue, currency: purchase.currency)
        event?.setReceipt(receipt, transactionId: purchase.transactionId)
        
        Adjust.trackEvent(event)
    }
    
    private func _trackSubscription(_ purchase: Purchase) {
        guard let receipt = Bundle.main.receipt else {
            fallback(.init(event: .purchase, message: "AppStore receipt was not found"))
            return
        }
        
        guard
            let price = AdjustConnector
                .priceFormatter
                .number(from: purchase.price) as? NSDecimalNumber
        else {
            fallback(.init(event: .purchase, message: "Unable to serialize price \(purchase.price)"))
            return
        }
        
        guard let subscription = ADJSubscription(
            price: price,
            currency: purchase.currency,
            transactionId: purchase.transactionId,
            andReceipt: receipt
        ) else {
            fallback(.init(event: .purchase, message: "Unable to create subscription"))
            return
        }
        
        Adjust.trackSubscription(subscription)
    }
    
    private func fallback(_ info: FallbackInfo) {
        guard let token = parameters.token(for: .unknown) else { return }
        let event = ADJEvent(token: token, info: info)
        Adjust.trackEvent(event)
    }
}

// MARK: Extensions
private extension Bundle {
    var receipt: Data? {
        return appStoreReceiptURL.flatMap { try? Data(contentsOf: $0) }
    }
}


private extension STKAd {
    static var isZeroIDFA: Bool {
        return "00000000-0000-0000-0000-000000000000" == advertisingIdentifier
    }
}


private extension ADJEvent {
    convenience init?(token: String, parameters: [String: Any]?) {
        self.init(eventToken: token)
        parameters?.forEach {
            if let value = $0.value as? String {
                self.addCallbackParameter($0.key, value: value)
                self.addPartnerParameter($0.key, value: value)
            }
        }
    }
    
    convenience init?(token: String, info: AdjustConnector.FallbackInfo) {
        self.init(
            token: token,
            parameters: [
                "event": info.event.rawValue,
                "reason": info.message
            ]
        )
    }
}
