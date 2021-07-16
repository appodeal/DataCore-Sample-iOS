//
//  ConsentManagerConnector.swift
//  HolisticSolutionSDK
//
//  Created by Stas Kochkin on 19.05.2021.
//  Copyright © 2021 com.appodeal. All rights reserved.
//

import Foundation
import StackConsentManager


@objc(HSConsentManagerConnector) final
class ConsentManagerConnector: NSObject, Service {
    struct Parameters {
        static let id: String = "consent_manager"
        var appKey: String
        var trackId: String
    }
    
    var name: String { Parameters.id }
    var sdkVersion: String { "1.1.0" }
    var version: String { sdkVersion + ".1" }
    
    private var completion: ((HSError?) -> ())?
    
    func initialize(
        _ parameters: Parameters,
        completion: @escaping (HSError?) -> ()
    ) {
        STKConsentManager.shared().synchronize(
            withAppKey: parameters.appKey,
            customParameters: ["track_id" : parameters.trackId]
        ) { [weak self] error in
            if let error = error  {
                completion(HSError.service(error.localizedDescription))
            } else if STKConsentManager.shared().shouldShowConsentDialog == .false {
                completion(nil)
            } else {
                self?.completion = completion
                self?.loadConsentDialog()
            }
        }
    }
    
    private func loadConsentDialog() {
        STKConsentManager.shared().loadConsentDialog { [weak self] error in
            if STKConsentManager.shared().isConsentDialogReady, let viewController = UIApplication.shared.topViewContoller {
                STKConsentManager.shared().showConsentDialog(
                    fromRootViewController: viewController,
                    delegate: self
                )
            } else {
                self?.completion?(.service("Unable to present consent dialog"))
            }
        }
    }
}


extension ConsentManagerConnector: Initializable {}


extension ConsentManagerConnector: STKConsentManagerDisplayDelegate {
    public func consentManagerWillShowDialog(_ consentManager: STKConsentManager) {}
    
    public func consentManager(_ consentManager: STKConsentManager, didFailToPresent error: Error) {
        completion?(.service(error.localizedDescription))
    }
    
    public func consentManagerDidDismissDialog(_ consentManager: STKConsentManager) {
        completion?(nil)
    }
}
