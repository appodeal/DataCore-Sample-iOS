//
//  AppDelegate.swift
//  Sample
//
//  Created by Stas Kochkin on 04.05.2020.
//  Copyright © 2020 com.appodeal. All rights reserved.
//

import UIKit
import Appodeal
import HolisticSolutionSDK
import FBSDKCoreKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    static let complete: Notification.Name = .init("HSAppCompleteNotification")
    
    struct AppodealConstants {
        static let appKey = "dee74c5129f53fc629a44a690a02296694e3eef99f2d3a5f"
        static let adType: AppodealAdType = .banner
    }
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let connectors: [Service.Type] = [
            AppsFlyerConnector.self,
            AdjustConnector.self,
            FirebaseConnector.self,
            FacebookConnector.self
        ]
        
        let configuration: AppConfiguration = .init(
            appKey: AppodealConstants.appKey,
            adTypes: AppodealConstants.adType
        )
        
        Appodeal.setTestingEnabled(true)
        Appodeal.hs.register(connectors: connectors)
        Appodeal.hs.initialize(
            application: application,
            launchOptions: launchOptions,
            configuration: configuration
        ) { _ in
            NotificationCenter.default.post(name: AppDelegate.complete, object: nil)
        }
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
    }
    
    func application(
        _ application: UIApplication,
        didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    ) {}
}
