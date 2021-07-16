//
//  HSInternalServices.swift
//  HolisticSolutionSDK
//
//  Created by Stas Kochkin on 01.07.2020.
//  Copyright © 2020 com.appodeal. All rights reserved.
//

import Foundation


struct Purchase {
    var productId, price, currency, transactionId: String
    var type: PurchaseType
    var additionalParameters: [String : Any]
}


protocol AttributionService: Service {
    func collect(
        receiveAttributionId: @escaping ((String) -> Void),
        receiveData: @escaping (([AnyHashable: Any]?) -> Void)
    )
    
    func validateAndTrackInAppPurchase(
        _ purchase: Purchase,
        success:(([AnyHashable: Any]) -> Void)?,
        failure:((Error?, Any?) -> Void)?
    )
}


protocol ProductTestingService: Service {
    func activateConfig(completion: @escaping (([AnyHashable: Any]?) -> Void))
}


protocol AnalyticsService: Service {
    func trackEvent(_ event: String, customParameters: [String: Any]?)
    func trackInAppPurchase(_ purchase: Purchase)
}
