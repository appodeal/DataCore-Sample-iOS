//
//  HSAttributionConfigurationOperation.swift
//  HolisticSolutionSDK
//
//  Created by Stas Kochkin on 26.06.2020.
//  Copyright © 2020 com.appodeal. All rights reserved.
//

import Foundation


final class AttributionOperation: CancellableAsynchronousOperation {
    var connectors: [AttributionService]!
    var advertising: Advertising!
    
    private lazy var group = DispatchGroup()
    
    override func main() {
        super.main()
        App.log("Start collecting of attribution data")
        connectors.forEach { connector in
            group.enter()
            DispatchQueue.main.async { [unowned connector] in
                connector.collect(
                    receiveAttributionId: { [weak self] in
                        App.log("Receive attribution id: \($0)")
                        self?.advertising.setAttributionId($0)
                    },
                    receiveData: { [weak self] data in
                        defer { self?.group.leave() }
                        guard let self = self, let data = data else { return }
                        App.log("Receive conversion data: \(data)")
                        self.advertising.setConversionData(data)
                    }
                )
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            App.log("Finish collecting of attribution data")
            self?.finish()
        }
    }
}
