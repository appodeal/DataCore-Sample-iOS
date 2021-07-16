//
//  HSProductTestSyncOperation.swift
//  HolisticSolutionSDK
//
//  Created by Stas Kochkin on 26.06.2020.
//  Copyright © 2020 com.appodeal. All rights reserved.
//

import Foundation


final class ProductTestSyncOperation: CancellableAsynchronousOperation {
    var productTesting: [ProductTestingService] = []
    var advertising: Advertising!

    private lazy var group = DispatchGroup()
    
    override func main() {
        super.main()
        App.log("Start activation of remote configs")
        productTesting.forEach { service in
            group.enter()
            service.activateConfig { [weak self] config in
                guard let self = self else { return }
                config.map(self.advertising.setProductTestData)
                self.group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            App.log("[HSApp] Finish activating of remote configs")
            self?.finish()
        }
    }
}
