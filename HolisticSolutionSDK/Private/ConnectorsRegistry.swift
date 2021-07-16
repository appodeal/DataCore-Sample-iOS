//
//  ConnectorsRegistry.swift
//  HolisticSolutionSDK
//
//  Created by Stas Kochkin on 26.05.2021.
//  Copyright © 2021 com.appodeal. All rights reserved.
//

import Foundation


struct ConnnectorsRegistry {
    private var connectors: [Service] = []
    
    private(set) var types: [Service.Type] = [
        AppodealConnector.self,
        ConsentManagerConnector.self
    ]

    var ad: Advertising {
        let ad = connectors.compactMap { $0 as? Advertising }.first
        guard let ad = ad else { fatalError("Appodeal connnector is not found") }
        return ad
    }
    
    mutating func register(connectors: [Service.Type]) {
        types.append(contentsOf: connectors)
    }
    
    mutating func store(_ connector: Service) {
        connectors.append(connector)
    }
    
    mutating func filter(closure: (Service) -> Bool) {
        connectors = connectors.filter(closure)
    }
    
    func types<T: Service>(of connectorType: T.Type) -> [T.Type] {
        return types.compactMap { $0 as? T.Type }
    }
    
    func initalizable(_ name: String) -> RawParametersInitializable? {
        return connectors
            .filter { $0.name == name}
            .compactMap { $0 as? RawParametersInitializable }
            .first
    }
    
    func all<T>() -> [T] {
        return connectors.compactMap { $0 as? T }
    }
}
