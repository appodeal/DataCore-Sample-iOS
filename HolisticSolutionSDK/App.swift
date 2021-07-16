//
//  HSApp.swift
//  HolisticSolutionSDK
//
//  Created by Stas Kochkin on 25.06.2020.
//  Copyright © 2020 com.appodeal. All rights reserved.
//

import Foundation
import UIKit
import Appodeal

/// Base class that provides initialisation
/// and synchronisation of whole components that used
/// for Holistic Solution
@objc(HSApp) final public
class App: NSObject {
    @objc static let sdkVersion: String = "2.0.0"
    @objc static let shared = App()
    
    private var configuration: AppConfiguration!
    private var registry: ConnnectorsRegistry = .init()
    
    fileprivate lazy var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.explorestack.hsapp.control-queue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .default
        return queue
    }()

    private func _initialize(
        application: UIApplication,
        launchOptions: [UIApplication.LaunchOptionsKey : Any]?,
        configuration: AppConfiguration,
        completion:((Error?) -> Void)?
    ) {
        // Store configuration
        self.configuration = configuration
        // Synchronize privacy operation
        let privacyOperation = InitializeServiceOperation<ConsentManagerConnector>(
            parameters: .init(
                appKey: configuration.appKey,
                trackId: configuration.id
            )
        )
        // Adapter for privacy operation
        let privacyAdapterOperation = BlockOperation { [unowned self, unowned privacyOperation] in
            privacyOperation.connector = self.registry.types(of: ConsentManagerConnector.self).first?.init()
        }
        privacyOperation.addDependency(privacyAdapterOperation)
        // Create and configure services connectors
        let setupConnectorsOperation = BlockOperation { [unowned self, unowned application] in
            self.registry.types.forEach {
                // Create service connector
                let service = $0.init()
                // Setup connector
                service.set?(application, launchOptions: launchOptions)
                service.set?(debug: self.configuration.debug)
                // Save connector
                self.registry.store($0.init())
            }
            // Pass track id
            self.registry.ad.setTrackId(self.configuration.id)
        }
        // Fetch services parameters
        let fetchParametersOperation = FetchServicesParametersOperation(
            appKey: configuration.appKey,
            trackId: configuration.id
        )
        // Adapter for fetch
        let fetchParametersAdapterOperation = BlockOperation { [unowned self, unowned fetchParametersOperation] in
            fetchParametersOperation.services = self.registry.all()
        }
        // Initialize services
        let initializeServicesOperation = InitializeServicesOperation()
        let initializeServicesAdapterOperation = BlockOperation { [unowned initializeServicesOperation, unowned fetchParametersOperation] in
            initializeServicesOperation.parameters = fetchParametersOperation.response
            initializeServicesOperation.connector = { [unowned self] name in
                return self.registry.initalizable(name)
            }
        }
        // Clear registry
        let removeUnusedConnectorsOperation = BlockOperation { [unowned fetchParametersOperation, unowned self] in
            let keys: [String] = fetchParametersOperation.response.flatMap { Array($0.keys) } ?? []
            self.registry.filter { $0 is AppodealConnector || keys.contains($0.name) }
        }
        // Append MMP
        let setMmpInfoOperation = BlockOperation { [unowned self] in
            if let mmp = (self.registry.all() as [AttributionService]).first {
                self.registry.ad.setMMP(mmp: mmp.name)
            }
        }
        
        removeUnusedConnectorsOperation.addDependency(fetchParametersOperation)
        fetchParametersOperation.addDependency(setupConnectorsOperation)
        fetchParametersOperation.addDependency(fetchParametersAdapterOperation)
        initializeServicesOperation.addDependency(initializeServicesAdapterOperation)
        initializeServicesAdapterOperation.addDependency(fetchParametersOperation)
        setMmpInfoOperation.addDependency(removeUnusedConnectorsOperation)
        // Collect attribution data
        let attributionOperation = AttributionOperation(timeout: configuration.timeout)
        let attributionAdapterOperation = BlockOperation { [unowned attributionOperation, unowned self] in
            attributionOperation.advertising = self.registry.ad
            attributionOperation.connectors = self.registry.all()
        }
        attributionOperation.addDependency(attributionAdapterOperation)
        
        // Sync remote config
        let syncRemoteConfigOperation = ProductTestSyncOperation(timeout: configuration.timeout)
        let syncRemoteConfigAdapterOperation = BlockOperation { [unowned syncRemoteConfigOperation, unowned self] in
            syncRemoteConfigOperation.advertising = self.registry.ad
            syncRemoteConfigOperation.productTesting = self.registry.all()
        }
        syncRemoteConfigOperation.addDependency(syncRemoteConfigAdapterOperation)
        
        let advertisingOperation = InitializeServiceOperation<AppodealConnector>(
            parameters: self.configuration
        )
        
        let advertisingAdapterOperation = BlockOperation { [unowned self, unowned advertisingOperation] in
            advertisingOperation.connector = self.registry.types(of: AppodealConnector.self).first?.init()
        }
                
        advertisingOperation.addDependency(advertisingAdapterOperation)
        
        let completionOperation = CompletionOperation { error in
            DispatchQueue.main.async {
                completion?(error)
            }
        }

        completionOperation.addDependency(privacyOperation)
        completionOperation.addDependency(fetchParametersOperation)
        completionOperation.addDependency(initializeServicesOperation)
        completionOperation.addDependency(attributionOperation)
        completionOperation.addDependency(syncRemoteConfigOperation)
        completionOperation.addDependency(advertisingOperation)

        queue.addOperations(
            [
                privacyAdapterOperation,
                privacyOperation,
                setupConnectorsOperation,
                fetchParametersAdapterOperation,
                fetchParametersOperation,
                removeUnusedConnectorsOperation,
                initializeServicesAdapterOperation,
                initializeServicesOperation,
                attributionAdapterOperation,
                attributionOperation,
                syncRemoteConfigAdapterOperation,
                syncRemoteConfigOperation,
                advertisingAdapterOperation,
                advertisingOperation,
                completionOperation,
                setMmpInfoOperation
            ],
            waitUntilFinished: false
        )
    }
}


internal extension App {
    static func log(_ message: String) {
        shared.configuration?.debug.log(message)
    }
}


extension App: DSL {
    @objc public
    func register(connectors: [Service.Type]) {
        registry.register(connectors: connectors)
    }
    
    @objc public
    func initialize(
        application: UIApplication,
        launchOptions: [UIApplication.LaunchOptionsKey : Any]?,
        configuration: AppConfiguration
    ) {
        initialize(
            application: application,
            launchOptions: launchOptions,
            configuration: configuration,
            completion: nil
        )
    }
    
    @objc public
    func initialize(
        application: UIApplication,
        launchOptions: [UIApplication.LaunchOptionsKey : Any]?,
        configuration: AppConfiguration,
        completion:((Error?) -> Void)?
    ) {
        _initialize(
            application: application,
            launchOptions: launchOptions,
            configuration: configuration,
            completion: completion
        )
    }
    
    @objc public
    func validateAndTrackInAppPurchase(
        productId: String,
        type: PurchaseType,
        price: String,
        currency: String,
        transactionId: String,
        additionalParameters: [String: Any],
        success:(([AnyHashable: Any]) -> Void)?,
        failure:((Error?, Any?) -> Void)?
    ) {
        let purchase = Purchase(
            productId: productId,
            price: price,
            currency: currency,
            transactionId: transactionId,
            type: type,
            additionalParameters: additionalParameters
        )
        
        let operation = ValidateAndTrackPurchaseOperation(
            purchase: purchase,
            success: success,
            failure: failure
        )
        
        let adapter = BlockOperation { [unowned self, unowned operation] in
            operation.analytics = self.registry.all()
            operation.attribution = self.registry.all()
        }
        
        operation.addDependency(adapter)
        queue.addOperations([adapter, operation], waitUntilFinished: false)
    }
    
    @objc public
    func trackEvent(
        _ eventName: String,
        customParameters: [String : Any]?
    ) {
        let trackEvent = TrackEventOperation(event: eventName, params: customParameters)
        let adapter = BlockOperation { [unowned self, unowned trackEvent] in
            trackEvent.analytics = self.registry.all()
        }
        
        trackEvent.addDependency(adapter)
        
        queue.addOperations([adapter, trackEvent], waitUntilFinished: false)
    }
}
