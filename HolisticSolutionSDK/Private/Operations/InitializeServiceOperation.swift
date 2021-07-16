//
//  SynchronizeConsentOperation.swift
//  HolisticSolutionSDK
//
//  Created by Stas Kochkin on 19.05.2021.
//  Copyright © 2021 com.appodeal. All rights reserved.
//

import Foundation


class InitializeServiceOperation<Connector>: AsynchronousOperation, ErrorProvider where Connector: Initializable & Service {
    var connector: Connector!
    let parameters: Connector.Parameters
    
    private(set) var error: HSError?
    
    init(parameters: Connector.Parameters) {
        self.parameters = parameters
        super.init()
    }
    
    override func main() {
        super.main()
        App.log("Initialize service \(connector.name)")
        DispatchQueue.main.async { [unowned self] in
            self.connector.initialize(self.parameters) { [weak self] error in
                guard let self = self else { return }
                defer { self.finish() }
                
                if let error = error {
                    self.error = error
                    App.log("Error while initializing service \(self.connector.name): \(error.nserror)")
                } else {
                    App.log("Complete service \(self.connector.name) initialization")
                }
            }
        }
    }
}


class InitializeServicesOperation: AsynchronousOperation {
    var parameters: RawParameters?
    var connector: ((String) -> RawParametersInitializable?)!
    
    private lazy var group = DispatchGroup()
    
    override func main() {
        super.main()
        guard let parameters = parameters, parameters.keys.count > 0 else {
            finish()
            return
        }
        
        App.log("Initialize services")
        parameters.keys.forEach { id in
            group.enter()
            if
                let connector = self.connector(id),
                let info = parameters[id] as? RawParameters
            {
                DispatchQueue.main.async { [unowned connector] in
                    let name = connector.name
                    App.log("Initialize service \(name)")
                    connector.initialize(info) { [weak self] error in
                        guard let self = self else { return }
                        defer { self.group.leave() }
                        if let error = error {
                            App.log("Error while initializing service \(name): \(error.nserror)")
                        } else {
                            App.log("Complete service \(name) initialization")
                        }
                    }
                }
            } else {
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            App.log("Complete services initialization")
            self?.finish()
        }
    }
}
