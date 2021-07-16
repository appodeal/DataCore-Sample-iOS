//
//  DSL.swift
//  HolisticSolutionSDK
//
//  Created by Stas Kochkin on 17.05.2021.
//  Copyright © 2021 com.appodeal. All rights reserved.
//

import Foundation
import UIKit
import Appodeal


internal enum HSError: Error {
    case integration(String)
    case timeout(String)
    case service(String)
    case unknown(String)
}


@objc(HSPurchaseType) public
enum PurchaseType: Int {
    case consumable = 0
    case nonConsumable
    case autoRenewableSubscription
    case nonRenewingSubscription
}


@objc(HSDSL) public
protocol DSL {
    func register(connectors: [Service.Type])

    func initialize(
        application: UIApplication,
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
        configuration: AppConfiguration
    )
    
    func initialize(
        application: UIApplication,
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
        configuration: AppConfiguration,
        completion: ((Error?) -> Void)?
    )
    
    func validateAndTrackInAppPurchase(
        productId: String,
        type: PurchaseType,
        price: String,
        currency: String,
        transactionId: String,
        additionalParameters: [String: Any],
        success:(([AnyHashable: Any]) -> Void)?,
        failure:((Error?, Any?) -> Void)?
    )
    
    func trackEvent(
        _ eventName: String,
        customParameters: [String: Any]?
    )
}


@objc public
extension Appodeal {
    @objc static
    var hs: DSL { App.shared }
}
